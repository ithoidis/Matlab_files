function [traj,infStates] = GBM(r, pvec, varargin)
% GENERAL BINARY (INPUT) MODEL

% NOTES
% 1. in and N defined separately
% 2. representation Mu has no variance in SDT, there is just noise (alpha)
% that influences it's mean value.
% 3. must be a two-level model because the 2nd level sets the prior for the
% first, even if the prior is static

% PLANNED UPDATES
% 1. Allow separate evaluation of alpha for targets and non-targets - done
% 2. Estimate prior expectation (static)
% 3. Prior and alpha variable by block type
% 4. Prior and alpha variable by trial (Kalman)
% 5. Hierarchical priors

% Transform paramaters back to their native space if needed
if ~isempty(varargin) 
    if strcmp(varargin{1},'trans')
        pvec = GBM_transp(r, pvec);
    end
end

% Add dummy "zeroth" trial
u = [zeros(1,size(r.u,2)); r.u(:,:)];

% Number of trials (including prior)
n = size(u,1);

% Assume that if u has more than one column, the last contains t
try
    if r.c_prc.irregular_intervals
        if size(u,2) > 1
            t = [0; r.u(:,end)];
        else
            error('tapas:hgf:InputSingleColumn', 'Input matrix must contain more than one column if irregular_intervals is set to true.');
        end
    else
        t = ones(n,1);
    end
catch
    if size(u,2) > 1
        t = [0; r.u(:,end)];
    else
        t = ones(n,1);
    end
end

%% INITIALISE

% Create param struct
nme=r.c_prc.pnames;
nme_gen=r.c_prc.pnames_gen;
idx=r.c_prc.priormusi;
type='like';
for pn=1:length(nme)
    if strcmp(nme{pn,1}(1:length(type)),type)
        eval([nme_gen{pn} ' = pvec(idx{pn})'';']);
    end
end

%levels
for m=1:r.c_prc.nModels
    type = r.c_prc.type{m};
    l(m) = r.c_prc.(type).n_priorlevels+1;
end
maxlev=max(l);

% Representations
nmod=r.c_prc.nModels;
mu0 = NaN(n,maxlev,nmod);
mu = NaN(n,maxlev,nmod);
pi = NaN(n,maxlev,nmod);

% Other quantities
muhat = NaN(n,maxlev,nmod);
pihat = NaN(n,maxlev,nmod);
v     = NaN(n,maxlev,nmod);
w     = NaN(n,maxlev,nmod);
da    = NaN(n,maxlev,nmod);
dau   = NaN(n,1,nmod);
g  = NaN(n,maxlev,nmod); % Kalman gain (optional)

al = NaN(n,1);
% joint trajectories (if needed)
vj_mu = NaN(n,1);
xc = NaN(n,1);
xchat = NaN(n,1);

% parameters
th = NaN(1,1,nmod);
    
for m=1:r.c_prc.nModels
    type = r.c_prc.type{m};
    
    % Create param struct
    for pn=1:length(nme)
        if strcmp(nme{pn,1}(1:length(type)),type)
            thispvec=nan(3,1);
            lenpvec=length(pvec(idx{pn}));
            thispvec(1:lenpvec)=pvec(idx{pn})';
            eval([nme_gen{pn} '(:,1,m) = thispvec;']);
        end
    end

    if exist('om','var')
        if l(m)>1
            th(1,1,m)   = exp(om(end,1,m));
            om(end,1,m)=NaN;
        end
    end

    % Representation priors
    % Note: first entries of the other quantities remain
    % NaN because they are undefined and are thrown away
    % at the end; their presence simply leads to consistent
    % trial indices.
    mu(1,1,m) = 1./(1+exp(-mu_0(1,1,m)));
    pi(1,1,m) = Inf;
    if l(m)>1
        mu(1,2:end,m) = mu_0(2:l(m),1,m);
        pi(1,2:end,m) = 1./sa_0(2:l(m),1,m);
    end
    if exist('g_0','var') && size(g_0,3)>=m
        g(1,:,m)  = g_0(1,1,m); % Kalman gain (optional)
        expom(:,1,m) = exp(om(:,1,m));
    end
end

%% Efficiacy
% Unpack from struct to double for efficiency
% type='like';
% pnames = fieldnames(M.(type).p);
% for pn=1:length(pnames)
%     eval([pnames{pn} ' = M.(type).p.(pnames{pn});']);
% end
% for m=1:r.c_prc.nModels
%     type = r.c_prc.type{m};
% 
%     % Unpack prior parameters
%     pnames = fieldnames(M.(type).p);
%     for pn=1:length(pnames)
%         eval([pnames{pn} '(:,:,m) = M.(type).p.(pnames{pn})'';']);
%     end
% 
%     %Unpack prior traj
% %     tnames = fieldnames(M.(type).tr);
% %     for tn=1:length(tnames)
% %         eval([tnames{tn} '(:,1:size(M.(type).tr.(tnames{tn}),2),m) = M.(type).tr.(tnames{tn});']);
% %     end
% end

% find out if certain variables exist or not
% no_al1=0;
% if ~exist('al1','var')
%     no_al1=1;
% end
no_rb=0;
if ~exist('rb','var')
    no_rb=1;
end
no_g=0;
if ~exist('g','var')
    no_g=1;
end

% get model structure
for m=1:r.c_prc.nModels
    type = r.c_prc.type{m};
    hierarchical(m)=0;
    static(m)=0;
    dynamic(m)=0;
    state(m)=0;
    if strcmp(r.c_prc.(type).priortype,'hierarchical')
        hierarchical(m)=1;
        if strcmp(r.c_prc.(type).priorupdate,'static')
            static(m)=1;
        elseif strcmp(r.c_prc.(type).priorupdate,'dynamic')
            dynamic(m)=1;
        end
    elseif strcmp(r.c_prc.(type).priortype,'state')
        state(m)=1;
    end
    AL(m)=0;
    PL(m)=0;
    if strcmp(r.c_prc.type{m},'AL')
        AL(m)=1;
    elseif strcmp(r.c_prc.type{m},'PL')
        PL(m)=1;
    end
end
inputfactors=r.c_prc.inputfactors;
n_inputfactors=length(inputfactors);
nModels=r.c_prc.nModels;

% ignore trials
no_ign = ones(1,n);
no_ign(r.ign) = 0;

%% UPDATES
for k=2:1:n
    
    for m=1:nModels
        if no_ign(k-1)
            
%             % Unpack likelihood parameters
%             type='like';
%             pnames = fieldnames(M.(type).p);
%             for pn=1:length(pnames)
%                 p.(pnames{pn}) = M.(type).p.(pnames{pn});
%             end
% 
           % type = r.c_prc.type{m};
%             
%             % Unpack prior parameters
%             pnames = fieldnames(M.(type).p);
%             for pn=1:length(pnames)
%                 p.(pnames{pn}) = M.(type).p.(pnames{pn});
%             end
%             
%             %Unpack prior traj
%             tnames = fieldnames(M.(type).tr);
%             for tn=1:length(tnames)
%                 tr.(tnames{tn}) = M.(type).tr.(tnames{tn});
%             end
        
            %% Predictions (from previous trial or static parameters)
            if hierarchical(m)
                if static(m)
                    %if r.c_prc.(type).n_muin>1
                    %    muhat(1,2,m) = mu_0(1+u(k,2),1,m);
                    %    pihat(1,2,m) = 1./sa_0(1+u(k,2),1,m);
                    %else
                        muhat(1,2,m) = mu_0(2,1,m);
                        pihat(1,2,m) = 1./sa_0(2,1,m);
                    %end
                    % 2nd level prediction
                    muhat(k,2,m) = muhat(1,2,m);%mu(k-1,2) +t(k) *rho(2); % fixed to initial value - not updated on each trial

                elseif dynamic(m)
                    % 2nd level prediction
                    muhat(k,2,m) = mu(k-1,2,m) +t(k) *rho(2,1,m);

                end
                % Prediction from level 2 (which can be either static or dynamic)
                muhat(k,1,m) = 1./(1+exp(-muhat(k,2,m)));

            elseif state(m)
                % Prediction from prior state, e.g. Kalman filter
                muhat(k,1,m) =  mu(k-1,1,m);

            end

            % Precision of prediction
            pihat(k,1,m) = 1/(muhat(k,1,m)*(1 -muhat(k,1,m)));


            %% Updates

            % Value prediction error, e.g. for Kalman filter, also known as the
            % "innovation"
            dau(k,1,m) = u(k,1) -muhat(k,1,m);

            % set alpha
%             if no_al1
%                 al1=al0;
%             end
            al(k,1,m)=al0(1);
            if n_inputfactors >0
                % apply gain to alpha according to input factors
                % alpha multipliers are not variances, but have to be positive
                if_str = num2str(u(k,2));
                for nif = 1:n_inputfactors 
                    if strcmp(if_str(inputfactors(nif)),'1')
                        al(k,1,m)=al(k,1,m) * al0(inputfactors(nif)+1);
                    end
                end
            end
            % 
            if hierarchical(m)
                % Likelihood functions: one for each
                % possible signal
%                 if n_inputcond >1
%                     und1 = exp(-(u(k) -eta1)^2/(2*al1(u(k,2))));
%                     und0 = exp(-(u(k) -eta0)^2/(2*al0(u(k,2))));
%                 else
%                     und1 = exp(-(u(k) -eta1)^2/(2*al1));
%                     und0 = exp(-(u(k) -eta0)^2/(2*al0));
%                 end
                und1 = exp(-(u(k) -eta1)^2/(2*al(k,1,m)));
                und0 = exp(-(u(k) -eta0)^2/(2*al(k,1,m)));

                if AL(m)
                    if u(k,3)==2
                        mu0(k,1,m) = muhat(k,1,m) *und1 /(muhat(k,1,m) *und1 +(1 -muhat(k,1,m)) *und0);
                        mu(k,1,m) = mu0(k,1,m);
                    elseif u(k,3)==1
                        mu0(k,1,m) = (1-muhat(k,1,m)) *und1 /(muhat(k,1,m) *und0 +(1 -muhat(k,1,m)) *und1);
                        mu(k,1,m) = 1-mu0(k,1,m);
                    end
                else
                    mu(k,1,m) = muhat(k,1,m) *und1 /(muhat(k,1,m) *und1 +(1 -muhat(k,1,m)) *und0);
                    mu0(k,1,m) = mu(k,1,m);
                end


                %%
                % Representation prediction error
                da(k,1,m) = mu(k,1,m) -muhat(k,1,m);

                % second level predictions and precisions
                if static(m)
                    mu(k,2,m) = muhat(k,2,m); % for a model with higher level predictions, which are static
                    % At second level, assume Inf precision for a model with invariable predictions
                    pi(k,2,m) = Inf;
                    pihat(k,2,m) = Inf;

                elseif dynamic(m)
                    % Precision of prediction
                    pihat(k,2,m) = 1/(1/pi(k-1,2,m) +exp(ka(2,1,m) *mu(k-1,3,m) +om(2,1,m)));

                    % Updates
                    pi(k,2,m) = pihat(k,2,m) +1/pihat(k,1,m);
                    mu(k,2,m) = muhat(k,2,m) +1/pi(k,2,m) *da(k,1,m);

                    % Volatility prediction error
                    da(k,2,m) = (1/pi(k,2,m) +(mu(k,2,m) -muhat(k,2,m))^2) *pihat(k,2,m) -1;
                end

                % Implied posterior precision at first level
                sgmmu2 = 1./(1+exp(-mu(k,2,m)));
                pi(k,1,m) = pi(k,2,m)/(sgmmu2*(1-sgmmu2));

                if l(m) > 3
                    % Pass through higher levels
                    % ~~~~~~~~~~~~~~~~~~~~~~~~~~
                    for j = 3:l(m)-1
                        % Prediction
                        muhat(k,j,m) = mu(k-1,j,m) +t(k) *rho(j,1,m);

                        % Precision of prediction
                        pihat(k,j,m) = 1/(1/pi(k-1,j,m) +t(k) *exp(ka(j,1,m) *mu(k-1,j+1,m) +om(j,1,m)));

                        % Weighting factor
                        v(k,j-1,m) = t(k) *exp(ka(j-1,1,m) *mu(k-1,j,m) +om(j-1,1,m));
                        w(k,j-1,m) = v(k,j-1,m) *pihat(k,j-1,m);

                        % Updates
                        pi(k,j,m) = pihat(k,j,m) +1/2 *ka(j-1,1,m)^2 *w(k,j-1,m) *(w(k,j-1,m) +(2 *w(k,j-1,m) -1) *da(k,j-1,m));

                        if pi(k,j,m) <= 0
                            error('tapas:hgf:NegPostPrec', 'Negative posterior precision. Parameters are in a region where model assumptions are violated.');
                        end

                        mu(k,j,m) = muhat(k,j,m) +1/2 *1/pi(k,j,m) *ka(j-1,1,m) *w(k,j-1,m) *da(k,j-1,m);

                        % Volatility prediction error
                        da(k,j,m) = (1/pi(k,j,m) +(mu(k,j,m) -muhat(k,j,m))^2) *pihat(k,j,m) -1;
                    end
                end
                if l(m)>2
                    % Last level
                    % ~~~~~~~~~~
                    % Prediction
                    muhat(k,l(m),m) = mu(k-1,l(m),m) +t(k) *rho(l(m),1,m);

                    % Precision of prediction
                    pihat(k,l(m),m) = 1/(1/pi(k-1,l(m),m) +t(k) *th(1,1,m));

                    % Weighting factor
                    v(k,l(m),m)   = t(k) *th(1,1,m);
                    v(k,l(m)-1,m) = t(k) *exp(ka(l(m)-1,1,m) *mu(k-1,l(m),m) +om(l(m)-1,1,m));
                    w(k,l(m)-1,m) = v(k,l(m)-1,m) *pihat(k,l(m)-1,m);

                    % Updates
                    pi(k,l(m),m) = pihat(k,l(m),m) +1/2 *ka(l(m)-1,1,m)^2 *w(k,l(m)-1,m) *(w(k,l(m)-1,m) +(2 *w(k,l(m)-1,m) -1) *da(k,l(m)-1,m));

                    if pi(k,l(m),m) <= 0
                        error('tapas:hgf:NegPostPrec', 'Negative posterior precision. Parameters are in a region where model assumptions are violated.');
                    end

                    mu(k,l(m),m) = muhat(k,l(m),m) +1/2 *1/pi(k,l(m),m) *ka(l(m)-1,1,m) *w(k,l(m)-1,m) *da(k,l(m)-1,m);

                    % Volatility prediction error
                    da(k,l(m),m) = (1/pi(k,l(m),m) +(mu(k,l(m),m) -muhat(k,l(m),m))^2) *pihat(k,l(m),m) -1;
                end

            elseif state(m) % Kalman
                % Gain update - optimal gain is calculated from ratio of input
                % variance to representation variance

                % Same gain function modified by two different alphas
                g(k,1,m) = (g(k-1,1,m) +al(k,1,m)*expom(1,1,m))/(g(k-1,1,m) +al(k,1,m)*expom(1,1,m) +1);
                % Hidden state mean update
                mu(k,1,m) = muhat(k,1,m)+g(k,1,m)*dau(k,1,m);
                mu0(k,1,m) = mu(k,1,m);
                pi(k,1,m) = (1-g(k,1,m)) *al(k,1,m)*expom(1,1,m); 

                % Alternative: separate gain functions for each stimulus type
          %      if r.c_prc.(type).one_alpha
          %          pi_u=al0(u(k,2));
          %          g(k,1) = (g(k-1,1) +pi_u*expom)/(g(k-1,1) +pi_u*expom +1);
          %          % Hidden state mean update
          %          mu(k,1,m) = muhat(k,1,m)+g(k,1)*dau(k);
          %          pi(k,1,m) = (1-g(k,1)) *pi_u*expom;
          %      else
          %          if u(k,1)==0
          %              pi_u=al0(u(k,2));
          %              g(k,1) = (g(k-1,1) +pi_u*expom)/(g(k-1,1) +pi_u*expom +1);
          %              g(k,2) = g(k-1,2);
          %              % Hidden state mean update
          %              mu(k,1,m) = muhat(k,1,m)+g(k,1)*dau(k);
          %              pi(k,1,m) = (1-g(k,1)) *pi_u*expom;
          %          elseif u(k,1)==1
          %              pi_u=al1(u(k,2));
          %              g(k,2) = (g(k-1,2) +pi_u*expom)/(g(k-1,2) +pi_u*expom +1);
          %              g(k,1) = g(k-1,1);
          %              % Hidden state mean update
          %              mu(k,1,m) = muhat(k,1,m)+g(k,2)*dau(k);
          %              pi(k,1,m) = (1-g(k,2)) *pi_u*expom;
          %          end
          %      end

                % Representation prediction error
                da(k,1,m) = mu(k,1,m) -muhat(k,1,m);

            end

            % RESPONSE BIAS
            if ~no_rb
                mu(k,1,m) = mu(k,1,m)+rb(1,1,m);
            end

        else
            mu(k,:,m) = mu(k-1,:,m); 
            pi(k,:,m) = pi(k-1,:,m);

            muhat(k,:,m) = muhat(k-1,:,m);
            pihat(k,:,m) = pihat(k-1,:,m);

            v(k,:,m)  = v(k-1,:,m);
            w(k,:,m)  = w(k-1,:,m);
            da(k,:,m) = da(k-1,:,m);
            dau(k,1,m) = dau(k-1,1,m);
            if no_g==0
                g(k,:,m)=g(k-1,:,m);
            end
            al(k,1,m)  = al(k-1,1,m);
        end
    end
    
    % Joint prediction if more than one model
    if nModels>1
        
        % set alpha
        if no_al1
            al1=al0;
        end
        if u(k,1)==0
            al(k,1,m)=al0(u(k,2));
        elseif u(k,1)==1
            al(k,1,m)=al1(u(k,2));
        end
        
        % joint probability
        vj_phi = sum(phi(1,1,:));
        vj_mu(k,1) = sum(phi(1,1,:).*mu0(k,1,:))/vj_phi;

        % joint prediction
            % ((eta1-vj_mu(k,1))^2 - (eta0-vj_mu(k,1))^2) gives a value between
            % -1 (if vj_mu is closer to eta1) and 1 (if closer to eta0).
            % dividing by vj_phi makes log(rt) either very large positive (if phi
            % is very precise) or very large negative (if uncertain). Exp of
            % these results in a large positive or small positive number
            % respectively.
            % So, when vj_mu is close to 0 and precise, xchat approaches 0
        
        rt=exp(((eta1-vj_mu(k,1))^2 - (eta0-vj_mu(k,1))^2)/(vj_phi^-2));
        xchat(k,1) = 1/(1+rt);
        
        
        % Likelihood functions: one for each
        % possible signal
        if n_inputcond >1
            und1 = exp(-(u(k,1) -eta1)^2/(2*al1(u(k,2))));
            und0 = exp(-(u(k,1) -eta0)^2/(2*al0(u(k,2))));
        else
            und1 = exp(-(u(k,1) -eta1)^2/(2*al1));
            und0 = exp(-(u(k,1) -eta0)^2/(2*al0));
        end

        % Update
        xc(k,1) = xchat(k,1) *und1 /(xchat(k,1) *und1 +(1 -xchat(k,1)) *und0);
        
    end
    
end

%% COMPILE RESULTS

for m=1:nModels
    if l(m)>1
        % Implied learning rate at the first level
        sgmmu2 = 1./(1+exp(-mu(:,2,m)));
        lr1    = diff(sgmmu2)./da(2:n,1,m);
        lr1(da(2:n,1,m)==0) = 0;
    end
end

% Remove representation priors
mu0(1,:,:)  = [];
mu(1,:,:)  = [];
pi(1,:,:)  = [];
al(1,:,:)     = [];
 
% joint trajectories (if needed)
vj_mu(1) = [];
xc(1) = [];
xchat(1) = [];

% Remove other dummy initial values
muhat(1,:,:) = [];
pihat(1,:,:) = [];
v(1,:,:)     = [];
w(1,:,:)     = [];
da(1,:,:)    = [];
dau(1,:,:)     = [];
if no_g==0
    g(1,:,:)  = [];
end

% Create result data structure
traj = struct;

for m=1:nModels

%     % Unpack likelihood parameters
%     type='like';
%     pnames = fieldnames(M.(type).p);
%     for pn=1:length(pnames)
%         p.(pnames{pn}) = (pnames{pn});
%     end

    type = r.c_prc.type{m};
    
%     % Unpack prior parameters
%     pnames = fieldnames(M.(type).p);
%     for pn=1:length(pnames)
%         p.(pnames{pn}) = (pnames{pn});
%     end
% 
%     %Unpack prior traj
%     tnames = fieldnames(M.(type).tr);
%     for tn=1:length(tnames)
%         tr.(tnames{tn}) = (tnames{tn});
%     end


    % Check validity of trajectories
    if any(isnan(mu(:,:,m))) %|| any(isnan(pi(:)))
        error('tapas:hgf:VarApproxInvalid', 'Variational approximation invalid. Parameters are in a region where model assumptions are violated.');
    else
        % Check for implausible jumps in trajectories
        % CAB: only use first 500 trials - after that changes in precision become too small
        ntrials = min(length(mu(:,:,m)),500);
        dmu = diff(mu(1:ntrials,2:end,m));
        dpi = diff(pi(1:ntrials,2:end,m));
        rmdmu = repmat(sqrt(mean(dmu.^2)),length(dmu),1);
        rmdpi = repmat(sqrt(mean(dpi.^2)),length(dpi),1);

        jumpTol = 16;
        if any(abs(dmu(:)) > jumpTol*rmdmu(:)) || any(abs(dpi(:)) > jumpTol*rmdpi(:))
            disp('hgf:VarApproxInvalid', 'GBM Variational approximation invalid. Parameters are in a region where model assumptions are violated.');
            disp('Use plot for diagnosis: see within function'); % plot(abs(dpi(:))); hold on; plot(rmdpi(:),'r'); hold on; plot(jumpTol*rmdpi(:),'g')
            clear traj
            return
        end
    end

    traj.like.vj_mu = vj_mu;
    traj.like.xc = xc;
    traj.like.xchat = xchat;

    traj.(type).mu0    = mu0(:,:,m);
    traj.(type).mu     = mu(:,:,m);
    traj.(type).sa     = 1./pi(:,:,m);

    traj.(type).muhat  = muhat(:,:,m);
    traj.(type).sahat  = 1./pihat(:,:,m);
    traj.(type).v      = v(:,:,m);
    traj.(type).w      = w(:,:,m);
    traj.(type).da     = da(:,:,m);
    traj.(type).dau    = dau(:,:,m);
    if no_g==0 && size(g,3)>=l(m)
        traj.(type).g     = g(:,:,m);
    end

    % Updates with respect to prediction
    traj.(type).ud = muhat(:,:,m) -mu(:,:,m);

    % Psi (precision weights on prediction errors)
    psi        = NaN(n-1,l(m)+1);
    psi(:,1)   = 1./(al(:,:,m).*pi(:,1,m)); % dot multiply only if al is a vector. More simply: psi1 = precision of input ./ 1st level precision
    if state(m); psi(:,2)   = 1./pi(:,1,m);end
    if l(m)>1; psi(:,2)   = 1./pi(:,2,m);end
    if l(m)>2; psi(:,3:l(m)) = pihat(:,2:l(m)-1,m)./pi(:,3:l(m),m);end
    traj.(type).psi   = psi;

    % Epsilons (precision-weighted prediction errors)
    epsi        = NaN(n-1,l(m));
    epsi(:,1)   = psi(:,1) .*dau(:,:,m);
    if state(m); epsi(:,2) = psi(:,2) .*da(:,1,m);end
    if l(m)>1; epsi(:,2:l(m)) = psi(:,2:l(m)) .*da(:,1:l(m)-1,m);end
    traj.(type).epsi   = epsi;

    % Full learning rate (full weights on prediction errors)
    wt        = NaN(n-1,l(m));
    if l(m)==1; lr1=psi(:,1);end
    wt(:,1)   = lr1;
    if l(m)>1; wt(:,2)   = psi(:,2); end
    if l(m)>2; wt(:,3:l(m)) = 1/2 *(v(:,2:l(m)-1,m) *diag(ka(2:l(m)-1,m))) .*psi(:,3:l(m)); end
    traj.(type).wt   = wt;

    % Create matrices for use by tapas observation models
     infStates = NaN(n-1,l(m),11);
%      infStates(:,:,1) = traj.(type).muhat;
%      infStates(:,:,2) = traj.(type).sahat;
%      infStates(:,:,3) = traj.(type).mu;
%      infStates(:,:,4) = traj.(type).sa;
%      infStates(:,:,5) = traj.(type).da;
%      infStates(:,:,6) = traj.(type).epsi;
%      infStates(:,1,7) = traj.(type).dau;
%     infStates(:,1,8) = traj.mu0;
%     infStates(:,1,9) = traj.vj_mu;
%     infStates(:,1,10) = traj.xc;
%     infStates(:,1,11) = traj.xchat;
end

return;
