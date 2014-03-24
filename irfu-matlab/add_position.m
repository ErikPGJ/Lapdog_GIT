function add_position(h,r)
%ADD_POSITION  add SC position to a plot
%
% ADD_POSITION(H,R)  Add position labels to axis with handle H
%
%   See also IRF_TIMEAXIS
%
% $Id: add_position.m,v 1.3 2011/06/08 17:12:36 andris Exp $

error(nargchk(2,2,nargin))

if ~ishandle(h), error('H is not an axis handle'), end
if isempty(r), irf_log('func','empty position'), return, end 
if size(r,2)~=4, error('R has bad size'), end

r = irf_abs(r);
irf_timeaxis(h,'usefig',[r(:,1) r(:,2:end)/6371.2],...
	{'X [Re]','Y [Re]','Z [Re]','R [Re]'})