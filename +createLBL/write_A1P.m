%
% Create LBL files for A1P TAB files.
%
%
% ARGUMENTS
% =========
% index                        : Lapdog's "index" variable.
% der_struct                   : Global variable "der_struct" defined by other Lapdog code. The function does not read
%                                the global variable by itself.
% dontReadHeaderKeyList        : Cell array of strings. PDS keys to not READ from source data set LBL file.
% TAB_LBL_inconsistency_policy : String. As defined in createLBL.create_OBJTABLE_LBL_file.
%
%
function write_A1P(kvl_LBL_all, index, der_struct, NO_ODL_UNIT, MISSING_CONSTANT, dontReadHeaderKeyList, TAB_LBL_inconsistency_policy)
%
% PROPOSAL: Do not write LBL file. Return ~LBL_data instead.
%   CON: Would be nice to have all dependence on "der_struct" here.
    
    for iFile = 1:numel(der_struct.file)
        startStopTimes = der_struct.timing(iFile, :);
        
        i_index = der_struct.firstind(iFile);        
        
        %--------------------------
        % Read the CALIB1 LBL file
        %--------------------------
        [kvl_LBL_CALIB, junk] = createLBL.read_LBL_file(...
            index(i_index).lblfile, dontReadHeaderKeyList, ...
            index(i_index).probe);
        
        kvl_LBL = kvl_LBL_all;
        kvl_LBL = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL, 'START_TIME',                   startStopTimes{1});        % UTC start time
        kvl_LBL = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL, 'STOP_TIME',                    startStopTimes{2});        % UTC stop time
        kvl_LBL = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL, 'SPACECRAFT_CLOCK_START_COUNT', startStopTimes{3});
        kvl_LBL = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL, 'SPACECRAFT_CLOCK_STOP_COUNT',  startStopTimes{4});
        
        kvl_LBL = lib_shared_EJ.KVPL.overwrite_values(kvl_LBL_CALIB, kvl_LBL, 'require preexisting keys');
        
        LBL_data = [];
        LBL_data.kvl_header = kvl_LBL;
        clear   kvl_LBL   kvl_LBL_CALIB
        
        LBL_data.N_TAB_file_rows = der_struct.rows(iFile);
        LBL_data.consistency_check.N_TAB_bytes_per_row = der_struct.bytes;
        LBL_data.consistency_check.N_TAB_columns       = der_struct.cols(iFile);
        
        LBL_data.OBJTABLE = [];
        LBL_data.OBJTABLE.DESCRIPTION = 'ANALYZED PROBE 1 PARAMETERS';
        
        ocl = [];
        ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
        ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION',  'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
        ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
        ocl{end+1} = struct('NAME', 'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION',  'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
        ocl{end+1} = struct('NAME', 'QUALITY',            'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  4, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'QUALITY FACTOR FROM 000 (BEST) TO 999.');
        ocl{end+1} = struct('NAME', 'Vph_knee',           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',         'MISSING_CONSTANT', MISSING_CONSTANT, 'DESCRIPTION', 'Potential at probe position from photoelectron current knee (gaussian fit of second derivative).');
        ocl{end+1} = struct('NAME', 'Te_exp_belowVknee',  'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'ELECTRONVOLT', 'MISSING_CONSTANT', MISSING_CONSTANT, 'DESCRIPTION', 'Electron temperature from an exponential fit to the slope of the retardation region of the electron current.');
        LBL_data.OBJTABLE.OBJCOL_list = ocl;
        clear ocl
        
        createLBL.create_OBJTABLE_LBL_file(der_struct.file{iFile}, LBL_data, TAB_LBL_inconsistency_policy);
        clear   LBL_data
        
    end   % for
    
end
