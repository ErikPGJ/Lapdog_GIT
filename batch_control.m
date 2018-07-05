%batch_control.m
%control file for lapdog.m

% Define the dataset:

%'lapdog: calling control...'
%control;

producerfullname='ERIK P G JOHANSSON';
producershortname='EJ';


% 2. Control section
% ==================
do_geom = 0;  % Geometry file preparation off/on
%do_mill = 1;  % Data processing  off/on. always on
fix_geom_bug = 1;  % To change signs of position and velocity coordinates

% 3. Versioning
% =============

% Info for labels
lbltime = '2016-08-18';  % Label revision time
lbleditor = 'EJ';
lblrev = 'Initial release';

% 4. Dataset selection and description
% ====================================

archivepath = archpath;
shortphase = archID;


% 5. Mission Calendar
% ====================================

%set when lapdog is called


% 6. Output path
% ====================================

derivedpath = strrep(archivepath, 'RPCLAP-3', 'RPCLAP-5');
derivedpath = strrep(derivedpath, 'CALIB',    'DERIV');
