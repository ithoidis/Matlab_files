function [pvec, pstruct] = mismatch_softmax_binary_transp(r, ptrans)
% --------------------------------------------------------------------------------------------------
% Copyright (C) 2016 Christoph Mathys, UZH & ETHZ
%
% This file is part of the HGF toolbox, which is released under the terms of the GNU General Public
% Licence (GPL), version 3. You can redistribute it and/or modify it under the terms of the GPL
% (either version 3 or, at your option, any later version). For further details, see the file
% COPYING or <http://www.gnu.org/licenses/>.

pvec    = NaN(1,length(ptrans));
pstruct = struct;

pvec(1)     = exp(ptrans(1));    % be
pstruct.be  = pvec(1);
pvec(2)     = ptrans(2);    % th
pstruct.th  = pvec(2);

return;
