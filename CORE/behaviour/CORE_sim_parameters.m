function S=CORE_sim_parameters(S)

S.sim.like_eta0 = 0;
S.sim.like_eta1 = 1;
S.sim.like_al0 = 1;
S.sim.like_al1 = 1;
S.sim.PR_mu_0 = 0.5;
S.sim.PR_g_0 = 0.1000;
S.sim.PR_om = -6;
S.sim.PR_phi = 2;
S.sim.PL_mu_0 = [NaN 0 1];
S.sim.PL_sa_0 = [NaN 0.5000 1];
S.sim.PL_rho = [NaN 0 0];
S.sim.PL_ka = [NaN 1];
S.sim.PL_om = [NaN -3 -3];
S.sim.PL_phi = 2;