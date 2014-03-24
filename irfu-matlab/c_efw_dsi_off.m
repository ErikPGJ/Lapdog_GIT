function [Ddsi,Damp] = c_efw_dsi_off(t,cl_id,Ps)
%C_EFW_DSI_OFF  get EFW offsets 
%
% [Ddsi,Damp] = c_efw_dsi_off(t,[cl_id,Ps])
%
% Ddsi is complex: Dx = real(Ddsi), Dy = imag(Ddsi)
%
% See also CAA_COROF_DSI
%
% $Id: c_efw_dsi_off.m,v 1.40 2012/09/10 14:52:58 jank Exp $

% ----------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <yuri@irfu.se> wrote this file.  As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return.   Yuri Khotyaintsev
% ----------------------------------------------------------------------------

error(nargchk(1,3,nargin))

SC_POT_LIM = -8;  % Above this we apply SW/SH correction, below - MS
TAV = 300; % Averaging window for SC potential
Damp = 1.1*ones(1,4);

% Table of SW/SH offsets
if t>=toepoch([2011 01 01 00 00 0]), Ddsi = [ 0.02  0.65  2.05  0.48 ];
elseif t>=toepoch([2010 12 01 00 00 0]), Ddsi = [ 0.4  1.1  2.72 0.84  ]; % Force MS offset for months when don't enter SW.
elseif t>=toepoch([2010 11 01 00 00 0]), Ddsi = [ 0.4  1.3  2.42 0.84  ]; % Force MS offset for months when don't enter SW.
elseif t>=toepoch([2010 07 12 00 00 0]), Ddsi = [ 0.4  1.6  1.22 0.84  ]; % Force MS offset for months when don't enter SW.
elseif t>=toepoch([2010 07 08 18 00 0]), Ddsi = [ -0.27 0.8  1.66 0.25 ]; % These orbits need the variable offset
elseif t>=toepoch([2010 07 01 00 00 0]), Ddsi = [ 0.4  1.6  1.22 0.84  ]; % Force MS offsets.
elseif t>=toepoch([2010 06 01 00 00 0]), Ddsi = [ -0.27 0.8  1.66 0.25 ];
elseif t>=toepoch([2010 02 01 00 0 0]), Ddsi = [ -0.34  0.67 1.50  0.17 ];
elseif t>=toepoch([2010 01 01 00 0 0]), Ddsi = [ -0.34  0.67 2.00  0.17 ];
elseif t>=toepoch([2009 12 01 00 00 0]), Ddsi = [-0.12    0.46 2.0 0.05];   % Increase C3 offset to bring in line with C124
elseif t>=toepoch([2009 11 13 00 00 0]), Ddsi = [-0.12    0.46 1.53 0.05];  % Back to variable offsets
elseif t>=toepoch([2009 07 01 00 00 0]), Ddsi = [ 0.46  1.33 1.27  0.65 ];  % Force MS offset for months when don't enter SW.
elseif t>=toepoch([2008 12 01 00 00 0]), Ddsi = [-0.12    0.46 1.53 0.05];  % Back to variable offsets
elseif t>=toepoch([2008 07 01 00 00 0]), Ddsi = [ 0.59    1.31 1.36  0.68]; % Force MS offset for months when don't enter SW.
elseif t>=toepoch([2008 01 01 00 00 0]), Ddsi = [-0.16    0.44 1.37 -0.03];
elseif t>=toepoch([2007 11 01 01 01 0]), Ddsi = [ 0.20    0.76 1.77 0.28];
elseif t>=toepoch([2007 08 05 01 01 0]), Ddsi = [0.70  1.45 1.49  0.85]; % Force MS offset for months when don't enter SW.
elseif t>=toepoch([2007 08 01 00 00 0]), Ddsi = [0.70  1.45+1.4 1.49  0.85]; % Force MS offset for months when don't enter SW.
elseif t>=toepoch([2007 07 21 18 45 0]), Ddsi = [-0.08     .46+1.4 1.65  .13 ]; % problem with guard settings on C2
elseif t>=toepoch([2007 02 01 00 00 0]), Ddsi = [-0.08     .46 1.65  .13 ]; % very approximate due to high-speed solar wind streams
elseif t>=toepoch([2007 01 01 00 00 0]), Ddsi = [-0.08     .46 1.95  .13 ]; % very approximate due to high-speed solar wind streams
elseif t>=toepoch([2006 10 01 00 00 0]), Ddsi = [ .24      .79 2.08  .57 ]; 
elseif t>=toepoch([2006 07 01 00 00 0]), Ddsi = [ .24      .79 1.70  .57 ]; 
elseif t>=toepoch([2006 02 01 00 00 0]), Ddsi = [ .40     1.03 2.08  .57 ]; 
elseif t>=toepoch([2006 01 01 00 00 0]), Ddsi = [ .40     1.13 2.08  .57 ]; 
elseif t>=toepoch([2005 07 01 00 00 0]), Ddsi = [ .31      .60 .52  .64 ]; % Big jump to 2006-01-01.
elseif t>=toepoch([2005 03 01 00 00 0]), Ddsi = [ .35+0.2i .78 .51  .62 ];
elseif t>=toepoch([2004 11 01 00 00 0]), Ddsi = [ .35      .78 .51  .62 ];
elseif t>=toepoch([2004 07 01 00 00 0]), Ddsi = [ .35      .78 .41  .42 ];
elseif t>=toepoch([2004 05 01 00 00 0]), Ddsi = [ .65      .95 .41  .42 ]; % manually checked
elseif t>=toepoch([2004 01 01 00 00 0]), Ddsi = [ .23      .72 .50  .42 ];
elseif t>=toepoch([2003 07 02 23 30 0]), Ddsi = [ .15      .53 .47  .71 ];
elseif t>=toepoch([2003 07 01 12 40 0]), Ddsi = [1.42      .53 .47  .71 ]; % HXONLY on C1 in the magnetosphere
elseif t>=toepoch([2002 12 02 00 00 0]), Ddsi = [ .15      .53 .47  .71 ];
elseif t>=toepoch([2002 05 02 00 00 0]), Ddsi = [ .33      .69 .73  .33 ];
elseif t>=toepoch([2002 01 01 00 00 0]), Ddsi = [ .33      .69 .73  .92 ];
elseif t>=toepoch([2001 07 01 00 00 0]), Ddsi = [ .47      .82 .89 1.04 ];
elseif t>=toepoch([2001 06 01 00 00 0]), Ddsi = [ .31      .60 .52  .64 ];
elseif t>=toepoch([2001 05 25 00 00 0]), Ddsi = [ .31     1.35 .52 1.55 ];
elseif t>=toepoch([2001 04 25 00 00 0]), Ddsi = [ .31      .60 .52  .64 ];
elseif t>=toepoch([2001 03 01 00 00 0]), Ddsi = [ .69     1.36 .68  .34 ];
elseif t>=toepoch([2001 02 02 15 00 0]), Ddsi = [ .55      .77 .44  .1  ]; 
elseif t>=toepoch([2001 02 02 00 00 0]), Ddsi = [ .48      .77 .44 1.11 ]; % Special puck/guard ?
elseif t>=toepoch([2001 02 01 00 00 0]), Ddsi = [ .55      .8  .4   .1  ];
else
	Ddsi = [ 0 0 0 0];
end

if nargin == 1, return, end 

DdsiSW = Ddsi;
Ddsi = Ddsi(cl_id);
Damp = Damp(cl_id);

if nargin == 2 || isempty(Ps), return, end 


ndata = ceil((Ps(end,1) - Ps(1,1))/TAV);
ta = Ps(1,1) + (1:ndata)*TAV - TAV/2; ta = ta';
Psr = irf_resamp( Ps( ~isnan(Ps(:,2)) ,:), ta, 'window',TAV);
if isempty(Psr), return, end

ii = find(Psr(:,2) < SC_POT_LIM);
if isempty(ii), return, end

% Table of MS offsets
if t>=toepoch([2011 01 01 00 0 0]), Ddsi = [ 0.68  0.78  1.22  0.79 ]; % C3 only 7 data points. using 2010 offset for C3
elseif t>=toepoch([2010 01 01 00 0 0]), Ddsi = [ 0.4  1.6  1.22 0.84 ];
elseif t>=toepoch([2009 01 01 00 0 0]), Ddsi = [ 0.46  1.33 1.27  0.65 ];
elseif t>=toepoch([2008 01 01 00 0 0]), Ddsi = [ 0.59  1.31 1.36  0.68 ];
elseif t>=toepoch([2007 11 01 00 0 0]), Ddsi = [ 0.70  1.45 1.69  0.85 ];
elseif t>=toepoch([2007 08 05 01 1 0]), Ddsi = [ 0.70  1.45 1.49  0.85 ];
elseif t>=toepoch([2007 07 21 18 45 0]), Ddsi = [ 0.70  1.45+1.4 1.49  0.85 ]; % problem with guard settings on C2
elseif t>=toepoch([2007 01 01 00 0 0]), Ddsi = [ 0.70  1.45 1.49  0.85 ];
elseif t>=toepoch([2006 10 01 00 0 0]), Ddsi = [ 0.83  1.53 1.68  1.00 ];
elseif t>=toepoch([2006 07 01 00 0 0]), Ddsi = [ 0.83  1.53 1.18  1.00 ];
elseif t>=toepoch([2006 01 01 00 0 0]), Ddsi = [ 0.83  1.53 1.68  1.00 ];
elseif t>=toepoch([2005 01 01 00 0 0]), Ddsi = [ 1.26  2.34 1.81  1.37 ];
elseif t>=toepoch([2004 01 01 00 0 0]), Ddsi = [ 1.35  2.06 1.45  1.15 ];
elseif t>=toepoch([2003 01 01 00 0 0]), Ddsi = [ 1.42  2.18 1.64  1.43 ];
elseif t>=toepoch([2002 12 02 00 0 0]), Ddsi = [ 1.42  1.98 1.64  2.00 ];
elseif t>=toepoch([2002 05 02 00 0 0]), Ddsi = [ 1.33  1.98 1.66  1.30 ];
elseif t>=toepoch([2002 01 01 00 0 0]), Ddsi = [ 1.33  1.98 1.66  2.00 ];
elseif t>=toepoch([2001 06 01 00 0 0]), Ddsi = [ 1.26  1.74 1.54  1.06 ];
elseif t>=toepoch([2001 02 01 00 0 0]), Ddsi = [ 1.21  1.92 1.25  1.02 ];
else
	Ddsi = DdsiSW;
end

% SC pot is all the time below SC_POT_LIM
if ~any(Psr(:,2) >= SC_POT_LIM), Ddsi = Ddsi(cl_id); return, end

DdsiMS = Ddsi;

Dd = Psr; clear Psr
Dd(:,1) = Dd(:,1) - TAV/2; % offset is set at the start of the interval
Dd(:,2) = DdsiSW(cl_id);
Dd(ii,2) = DdsiMS(cl_id);

% Remove repeating points
d = [1; diff(Dd(:,2))]; d(d~=0) = 1;
Ddsi = Dd(d==1,:);

