%createLBL.m
%CREATE .LBL FILES, FROM PREVIOUS LBL FILES

% BUG?: RECORD_BYTES should be number of TAB file rows, not TAB file size?!

t_start = clock;    % NOTE: Not number of seconds, but [year month day hour minute seconds].
warnings_settings = warning('query');
warning('on', 'all')
general_TAB_LBL_inconsistency_policy = 'warning';
AxS_TAB_LBL_inconsistency_policy     = 'warning';


% "Constants"
% NO_ODL_UNIT: Constant to be used for LBL "UNIT" fields meaning that there is no unit. To distinguish that it
% is know that the quantity has no unit rather than that the unit is unknown at present.
NO_ODL_UNIT       = [];   
ODL_VALUE_UNKNOWN = [];   %'<Unknown>';  % Unit is unknown.
delete_header_key_list = {'FILE_NAME', '^TABLE', 'PRODUCT_ID', 'RECORD_BYTES', 'FILE_RECORDS', 'RECORD_TYPE'};



%====================================================================================================
% Construct list of key-value pairs to use for all LBL files.
% -----------------------------------------------------------
% Keys must not collide with keys set for specific file types.
% For file types that read CALIB LBL files, must overwrite old keys(!).
% 
% NOTE: Only keys that already exist in the CALIB files that are read (otherwise intentional error)
%       and which are thus overwritten.
% NOTE: Might not be complete.
%====================================================================================================
kvl_LBL_all = [];
kvl_LBL_all.keys = {};
kvl_LBL_all.values = {};
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'PDS_VERSION_ID',            'PDS3');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'DATA_QUALITY_ID',           '"1"');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'PRODUCT_CREATION_TIME',     datestr(now, 'yyyy-mm-ddTHH:MM:SS.FFF'));
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'PRODUCT_TYPE',              '"DDR"');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'PROCESSING_LEVEL_ID',       '"5"');

kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'DATA_SET_ID',               ['"', strrep(datasetid,   sprintf('-3-%s-CALIB', shortphase), sprintf('-5-%s-DERIV', shortphase)), '"']);
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'DATA_SET_NAME',             ['"', strrep(datasetname, sprintf( '3 %s CALIB', shortphase), sprintf( '5 %s DERIV', shortphase)), '"']);
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'LABEL_REVISION_NOTE',       sprintf('"%s, %s, %s"', lbltime, lbleditor, lblrev));
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'PRODUCER_FULL_NAME',        sprintf('"%s"', producerfullname));
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'PRODUCER_ID',               producershortname);
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'PRODUCER_INSTITUTION_NAME', '"SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'INSTRUMENT_HOST_ID',        'RO');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'INSTRUMENT_HOST_NAME',      '"ROSETTA-ORBITER"');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'INSTRUMENT_NAME',           '"ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'INSTRUMENT_TYPE',           '"PLASMA INSTRUMENT"');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'INSTRUMENT_ID',             'RPCLAP');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'TARGET_NAME',               sprintf('"%s"', targetfullname));
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'TARGET_TYPE',               sprintf('"%s"', targettype));
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'MISSION_ID',                'ROSETTA');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'MISSION_NAME',              sprintf('"%s"', 'INTERNATIONAL ROSETTA MISSION'));
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'MISSION_PHASE_NAME',        sprintf('"%s"', missionphase));
%kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, '', );



%===============================================
%
% Create LBL files for (TAB files in) tabindex.
%
%===============================================
if(~isempty(tabindex));
    len= length(tabindex(:,3));
    
    for(i=1:len)
        try

            %tabindex cell array = {tab file name, first index number of batch,
            % UTC time of last row, S/C time of last row, row counter}
            %    units: [cell array] =  {[string],[double],[string],[float],[integer]
            
            LBL_data = [];
            LBL_data.consistency_check.N_TAB_columns = tabindex{i, 7};
            % LBL_data.consistency_check.N_TAB_bytes_per_row can not be set centrally here
            % since it is hardcoded for some TAB file types.
            
            %=========================================
            %
            % LBL file: Create header/key-value pairs
            %
            %=========================================
            
            tname = tabindex{i,2};
            lname=strrep(tname,'TAB','LBL');
            Pnum = index(tabindex{i,3}).probe;

            [kvl_LBL_CALIB, CALIB_LBL_struct] = createLBL_read_LBL_file(index(tabindex{i,3}).lblfile, delete_header_key_list, index(tabindex{i,3}).probe);
            
            
            SPACECRAFT_CLOCK_STOP_COUNT = sprintf('"%s/%014.3f"', index(tabindex{i,3}).sct0str(2), obt2sct(tabindex{i,5})); % get resetcount from above, and calculate obt from sct

            kvl_LBL = kvl_LBL_all;
            kvl_LBL = createLBL_KVPL_add_kv_pair(kvl_LBL, 'START_TIME',                   index(tabindex{i,3}).t0str(1:23));  % UTC start time
            kvl_LBL = createLBL_KVPL_add_kv_pair(kvl_LBL, 'STOP_TIME',                    tabindex{i,4}(1:23));               % UTC stop time
            kvl_LBL = createLBL_KVPL_add_kv_pair(kvl_LBL, 'SPACECRAFT_CLOCK_START_COUNT', index(tabindex{i,3}).sct0str);
            kvl_LBL = createLBL_KVPL_add_kv_pair(kvl_LBL, 'SPACECRAFT_CLOCK_STOP_COUNT',  SPACECRAFT_CLOCK_STOP_COUNT);
            
            kvl_LBL = createLBL_KVPL_overwrite_values(kvl_LBL_CALIB, kvl_LBL);
            
            LBL_data.kvl_header = kvl_LBL;
            clear   kvl_LBL kvl_LBL_CALIB
            
            
            
            LBL_data.N_TAB_file_rows = tabindex{i, 6};
            
            

            %=======================================
            %
            % LBL file: Create OBJECT TABLE section
            %
            %=======================================
            if (tname(30)=='S')
                
                %=========================
                % CASE: Sweep files (xxS)
                %=========================
                
                if (tname(28)=='B')

                    LBL_data.OBJTABLE = [];
                    LBL_data.consistency_check.N_TAB_bytes_per_row   = 32;              % NOTE: HARDCODED! Can not trivially take value from creation of file and read from tabindex.
                    LBL_data.OBJTABLE.DESCRIPTION = sprintf('%s Sweep step bias and time between each step', CALIB_LBL_struct.OBJECT___TABLE{1}.DESCRIPTION);
                    ocl = [];
                    ocl{end+1} = struct('NAME', 'SWEEP_TIME',                 'FORMAT', 'E14.7', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'SECONDS', 'DESCRIPTION', 'LAPSED TIME (S/C CLOCK TIME) FROM FIRST SWEEP MEASUREMENT');
                    ocl{end+1} = struct('NAME', sprintf('P%i_VOLTAGE', Pnum), 'FORMAT', 'E14.7', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'VOLT',    'DESCRIPTION', 'CALIBRATED VOLTAGE BIAS');
                    LBL_data.OBJTABLE.OBJCOL_list = ocl;
                    clear ocl

                else %% if tname(28) =='I'

                    Bfile = tname;
                    Bfile(28) = 'B';
                    
                    LBL_data.OBJTABLE = [];
                    LBL_data.consistency_check.N_TAB_bytes_per_row = tabindex{i, 8};
                    LBL_data.OBJTABLE.DESCRIPTION = sprintf('%s', CALIB_LBL_struct.OBJECT___TABLE{1}.DESCRIPTION);
                    ocl = [];
                    ocl{end+1} = struct('NAME', 'START_TIME_UTC',                   'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
                    ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',                    'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
                    ocl{end+1} = struct('NAME', 'START_TIME_OBT',                   'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS', 'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
                    ocl{end+1} = struct('NAME', 'STOP_TIME_OBT',                    'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS', 'DESCRIPTION', 'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
                    ocl{end+1} = struct('NAME', 'QUALITY',                          'DATA_TYPE', 'ASCII_REAL', 'BYTES', 3,  'UNIT', 'N/A',     'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');
                    ocl{end+1} = struct('NAME', sprintf('P%i_SWEEP_CURRENT', Pnum), 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'AMPERE', 'ITEMS', tabindex{i,7}-5, 'FORMAT', 'E14.7', ...
                        'DESCRIPTION', sprintf('Averaged current measured of potential sweep, at different potential steps as described by %s', Bfile));
                    
                    LBL_data.OBJTABLE.OBJCOL_list = ocl;
                    clear ocl
                end


            else
                %=============================================
                % CASE: Anything EXCEPT sweep files (NOT xxS)
                %=============================================
                
                LBL_data.OBJTABLE = [];
                LBL_data.consistency_check.N_TAB_columns     = 5;                % NOTE: Hardcoded. TODO: Fix!
                LBL_data.OBJTABLE.DESCRIPTION = CALIB_LBL_struct.OBJECT___TABLE{1}.DESCRIPTION;    % BUG: Possibly double quotation marks.
                if Pnum ~= 3
                    LBL_data.consistency_check.N_TAB_bytes_per_row = 83;  % NOTE: Hardcoded.
                else
                    LBL_data.consistency_check.N_TAB_bytes_per_row = 98;
                end                
                %LBL_data.consistency_check.N_TAB_bytes_per_row   = tabindex{i, 8};    % Can be empty. ==> Does not work.
                
                % -----------------------------------------------------------------------------
                % Recycle OBJCOL info/columns from CALIB LBL file (!) and then add one column.
                % -----------------------------------------------------------------------------
                ocl = CALIB_LBL_struct.OBJECT___TABLE{1}.OBJECT___COLUMN;
                for i_oc = 1:length(ocl)
                    oc = ocl{i_oc};
                    ocl{i_oc} = rmfield(oc, 'START_BYTE');
                    
                    % Add UNIT for UTC_TIME since it does not seem to have it already in the CALIB LBL file.
                    if strcmp(oc.NAME, 'UTC_TIME') && ~isfield(oc, 'UNIT')
                        ocl{i_oc}.UNIT = 'SECONDS';
                    end
                end
                ocl{end+1} = struct('NAME', 'QUALITY', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 3, 'UNIT', NO_ODL_UNIT, ...
                    'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');
                
                LBL_data.OBJTABLE.OBJCOL_list = ocl;
                clear ocl

            end
            
            createLBL_create_OBJTABLE_LBL_file(tabindex{i,1}, LBL_data, general_TAB_LBL_inconsistency_policy);            
            clear   LBL_data

        catch err
            
            fprintf(1,'\nlapdog:createLBL error message:%s\n',err.message);    
    
            len = length(err.stack);
            if (~isempty(len))
                for i=1:len
                    fprintf(1,'%s, %i,\n',err.stack(i).name,err.stack(i).line);
                end
            end
    
            fprintf(1,'\nlapdog: Skipping LBL file, continuing...\n');    
        end    % try
    end    % for
end    % if



%===============================================
%
% Create LBL files for (TAB files in) blockTAB.
%
%===============================================
if(~isempty(blockTAB));
    len=length(blockTAB(:,3));
    for(i=1:len)        
        
        LBL_data = [];
        LBL_data.consistency_check.N_TAB_columns   = 3;
        LBL_data.consistency_check.N_TAB_bytes_per_row = 55;                   % NOTE: HARDCODED! TODO: Fix.

        
        
        %=========================================
        %
        % LBL file: Create header/key-value pairs
        %
        % NOTE: Does not rely on reading old LBL file.
        %=========================================

        LBL_data.kvl_header = kvl_LBL_all;
        
        

        %=======================================
        % LBL file: Create OBJECT TABLE section
        %=======================================
        
        LBL_data.N_TAB_file_rows                      = blockTAB{i,3};
        LBL_data.OBJTABLE = [];
        LBL_data.OBJTABLE.DESCRIPTION = 'BLOCKLIST DATA. START & STOP TIME OF MACROBLOCK AND MACROID.';
        ocl = [];
        ocl{end+1} = struct('NAME', 'START_TIME_UTC', 'DATA_TYPE', 'TIME',       'BYTES', 23, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START TIME OF MACRO BLOCK YYYY-MM-DD HH:MM:SS.sss');
        ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',  'DATA_TYPE', 'TIME',       'BYTES', 23, 'UNIT', 'SECONDS',   'DESCRIPTION', 'LAST START TIME OF MACRO BLOCK FILE YYYY-MM-DD HH:MM:SS.sss');
        ocl{end+1} = struct('NAME', 'MACRO_ID',       'DATA_TYPE', 'ASCII_REAL', 'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'MACRO IDENTIFICATION NUMBER');
        LBL_data.OBJTABLE.OBJCOL_list = ocl;
        clear   ocl
        
        createLBL_create_OBJTABLE_LBL_file(blockTAB{i,1}, LBL_data, general_TAB_LBL_inconsistency_policy);
        clear   LBL_data
        
    end   % for
    
end   % if 



%==================================================
%
% Create LBL files for (TAB files in) an_tabindex.
%
%==================================================
if (~isempty(an_tabindex));
    len=length(an_tabindex(:,3));
    
    for (i=1:len)
                
        TAB_LBL_inconsistency_policy = general_TAB_LBL_inconsistency_policy;   % Default value, unless overwritten for specific data file types.
        
        tname = an_tabindex{i,2};
        lname = strrep(tname,'TAB','LBL');
        
        mode = tname(end-6:end-4);
        Pnum = index(an_tabindex{i,3}).probe;     % Probe number
        
        LBL_data = [];
        LBL_data.N_TAB_file_rows = an_tabindex{i, 4};
        LBL_data.consistency_check.N_TAB_bytes_per_row = an_tabindex{i,9};
        LBL_data.consistency_check.N_TAB_columns       = an_tabindex{i,5};
        
        
        %=========================================
        %
        % LBL file: Create header/key-value pairs
        %
        %=========================================
        
        if strcmp(an_tabindex{i,7}, 'best_estimates')
            %======================
            % CASE: Best estimates
            %======================
            
            TAB_file_info = dir(an_tabindex{i, 1});
            kvl_LBL = kvl_LBL_all;
            kvl_LBL = createLBL_KVPL_add_kv_pair(kvl_LBL, 'DESCRIPTION', '"Best estimates of physical quantities based on sweeps."');
            try
                %===============================================================
                % NOTE: createLBL_create_EST_LBL_header(...)
                % sets certain LBL/ODL variables to handle collisions:
                %    START_TIME / STOP_TIME,
                %    SPACECRAFT_CLOCK_START_COUNT / SPACECRAFT_CLOCK_STOP_COUNT
                %===============================================================
                
                kvl_LBL = createLBL_create_EST_LBL_header(an_tabindex(i, :), index, kvl_LBL, delete_header_key_list);    % NOTE: Reads LBL file(s).
                LBL_data.kvl_header = kvl_LBL;
                clear kvl_LBL
                
            catch exc
                fprintf(1, ['ERROR: ', exc.message])
                fprintf(1, exc.getReport)
                
                continue
            end
            
        else
            %====================================================
            % CASE: Anything type of file EXCEPT best estimates.
            %====================================================
            
            [kvl_LBL_CALIB, CALIB_LBL_struct] = createLBL_read_LBL_file(index(an_tabindex{i,3}).lblfile, delete_header_key_list, index(an_tabindex{i,3}).probe);
            
            % Add DESCRIPTION?!!
            kvl_LBL = createLBL_KVPL_overwrite_values(kvl_LBL_CALIB, kvl_LBL_all);
            
            LBL_data.kvl_header = kvl_LBL;
            clear kvl_LBL kvl_LBL_CALIB

        end   % if-else
        
        
        
        %=======================================
        %
        % LBL file: Create OBJECT TABLE section
        %
        %=======================================        
        
        if strcmp(an_tabindex{i,7}, 'downsample')   %%%%%%%%DOWNSAMPLED FILE%%%%%%%%%%%%%%%
            
           
            
            LBL_data.OBJTABLE = [];
            LBL_data.OBJTABLE.DESCRIPTION = sprintf('"%s %s SECONDS DOWNSAMPLED"', CALIB_LBL_struct.DESCRIPTION, lname(end-10:end-9));
            ocl = {};
            ocl{end+1} = struct('NAME', 'TIME_UTC',                          'UNIT', 'SECONDS',   'BYTES', 23, 'DATA_TYPE', 'TIME',                          'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl{end+1} = struct('NAME', 'OBT_TIME',                          'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL',                    'DESCRIPTION', 'SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
            ocl{end+1} = struct('NAME', sprintf('P%i_CURRENT',        Pnum), 'UNIT', 'AMPERE',    'BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', 'FORMAT', 'E14.7', 'DESCRIPTION', 'AVERAGED CURRENT');
            ocl{end+1} = struct('NAME', sprintf('P%i_CURRENT_STDDEV', Pnum), 'UNIT', 'AMPERE',    'BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', 'FORMAT', 'E14.7', 'DESCRIPTION', 'CURRENT STANDARD DEVIATION');
            ocl{end+1} = struct('NAME', sprintf('P%i_VOLT',           Pnum), 'UNIT', 'VOLT',      'BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', 'FORMAT', 'E14.7', 'DESCRIPTION', 'AVERAGED MEASURED VOLTAGE');
            ocl{end+1} = struct('NAME', sprintf('P%i_VOLT_STDDEV',    Pnum), 'UNIT', 'VOLT',      'BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', 'FORMAT', 'E14.7', 'DESCRIPTION', 'VOLTAGE STANDARD DEVIATION');
            ocl{end+1} = struct('NAME', 'QUALITY',                           'UNIT', NO_ODL_UNIT, 'BYTES',  3, 'DATA_TYPE', 'ASCII_REAL',                    'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');
            LBL_data.OBJTABLE.OBJCOL_list = ocl;
            clear ocl
            
            
            
        elseif strcmp(an_tabindex{i,7}, 'spectra')   %%%%%%%%%%%%%%%%SPECTRA FILE%%%%%%%%%%            
            
            
                    
            LBL_data.OBJTABLE = [];
            LBL_data.OBJTABLE.DESCRIPTION = sprintf('%s PSD SPECTRA OF HIGH FREQUENCY MEASUREMENT', mode);
            %---------------------------------------------
            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_UTC', 'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_UTC',  'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'SPECTRA STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_OBT', 'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
            ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_OBT',  'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
            ocl1{end+1} = struct('NAME', 'QUALITY',                'UNIT', NO_ODL_UNIT, 'BYTES', 3,  'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');
            %---------------------------------------------
            ocl2 = {};
            if strcmp(mode(1), 'I')
                
                if Pnum == 3
                    ocl2{end+1} = struct('NAME', 'P1-P2_CURRENT MEAN',                                 'UNIT', 'VOLT',            'DESCRIPTION', 'BIAS VOLTAGE');
                    ocl2{end+1} = struct('NAME', 'P1_VOLT',                                            'UNIT', 'VOLT',            'DESCRIPTION', 'BIAS VOLTAGE');
                    ocl2{end+1} = struct('NAME', 'P2_VOLT',                                            'UNIT', 'VOLT',            'DESCRIPTION', 'BIAS VOLTAGE');
                    ocl2{end+1} = struct('NAME', sprintf('PSD_%s', mode), 'ITEMS', an_tabindex{i,5}-7, 'UNIT', ODL_VALUE_UNKNOWN, 'DESCRIPTION', 'PSD CURRENT SPECTRUM');
                else                    
                    ocl2{end+1} = struct('NAME', sprintf('P%i_CURRENT_MEAN', Pnum),                    'UNIT', 'AMPERE',          'DESCRIPTION', 'CURRENT MEAN');
                    ocl2{end+1} = struct('NAME', sprintf('P%i_VOLT_MEAN',    Pnum),                    'UNIT', 'VOLT',            'DESCRIPTION', 'VOLTAGE MEAN');
                    ocl2{end+1} = struct('NAME', sprintf('PSD_%s', mode), 'ITEMS', an_tabindex{i,5}-7, 'UNIT', ODL_VALUE_UNKNOWN, 'DESCRIPTION', 'PSD CURRENT SPECTRUM');
                end
                
            elseif strcmp(mode(1),'V')
                
                if Pnum == 3
                    ocl2{end+1} = struct('NAME', 'P1_CURRENT_MEAN',                                   'UNIT', 'AMPERE',          'DESCRIPTION', 'CURRENT MEAN');
                    ocl2{end+1} = struct('NAME', 'P2_CURRENT_MEAN',                                   'UNIT', 'AMPERE',          'DESCRIPTION', 'CURRENT MEAN');
                    ocl2{end+1} = struct('NAME', 'P1-P2 VOLTAGE MEAN',                                'UNIT', 'VOLT',            'DESCRIPTION', 'MEAN VOLTAGE DIFFERENCE');
                    ocl2{end+1} = struct('NAME', sprintf('PSD_%s',mode), 'ITEMS', an_tabindex{i,5}-7, 'UNIT', ODL_VALUE_UNKNOWN, 'DESCRIPTION', 'PSD VOLTAGE SPECTRUM');
                else
                    ocl2{end+1} = struct('NAME', sprintf('P%i_CURRENT',   Pnum),                      'UNIT', 'AMPERE',          'DESCRIPTION', 'CURRENT MEAN');
                    ocl2{end+1} = struct('NAME', sprintf('P%i_VOLT_MEAN', Pnum),                      'UNIT', 'VOLT',            'DESCRIPTION', 'VOLTAGE MEAN');
                    ocl2{end+1} = struct('NAME', sprintf('PSD_%s',mode), 'ITEMS', an_tabindex{i,5}-7, 'UNIT', ODL_VALUE_UNKNOWN, 'DESCRIPTION', 'PSD VOLTAGE SPECTRUM');
                end                
                
            else
                fprintf(1, 'Error, bad mode identifier in an_tabindex{%i,1}', i);
            end
            for i_oc = 1:length(ocl2)
                ocl2{i_oc}.BYTES     = 14;
                ocl2{i_oc}.DATA_TYPE = 'ASCII_REAL';
                ocl2{i_oc}.FORMAT    = 'E14.7';
            end

            LBL_data.OBJTABLE.OBJCOL_list = [ocl1, ocl2];
            clear ocl1 ocl2
            
            
            
        elseif  strcmp(an_tabindex{i,7}, 'frequency')    %%%%%%%%%%%% FREQUENCY FILE %%%%%%%%%
            
            
            
            psdname = strrep(an_tabindex{i,2}, 'FRQ', 'PSD');
            
            LBL_data.OBJTABLE = [];
            LBL_data.OBJTABLE.DESCRIPTION = 'FREQUENCY LIST OF PSD SPECTRA FILE';
            ocl = {};
            ocl{end+1} = struct('NAME', 'FREQUENCY_LIST', 'ITEMS', an_tabindex{i,5}, 'UNIT', 'kHz', 'BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', ...
                'FORMAT', 'E14.7', 'DESCRIPTION', sprintf('FREQUENCY LIST OF PSD SPECTRA FILE %s', psdname));
            LBL_data.OBJTABLE.OBJCOL_list = ocl; 
            clear   ocl pdsname
            
            
            
        elseif  strcmp(an_tabindex{i,7}, 'sweep')    %%%%%%%%%%%% SWEEP ANALYSIS FILE %%%%%%%%%
            
            
            
            LBL_data.OBJTABLE = [];
            LBL_data.OBJTABLE.DESCRIPTION = sprintf('MODEL FITTED ANALYSIS OF %s SWEEP FILE', tabindex{an_tabindex{i,6}, 2});

            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'START_TIME(UTC)', 'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'Start time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl1{end+1} = struct('NAME', 'STOP_TIME(UTC)',  'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION',  'Stop time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl1{end+1} = struct('NAME', 'START_TIME_OBT',  'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Start time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl1{end+1} = struct('NAME', 'STOP_TIME_OBT',   'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION',  'Stop time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');            
            ocl1{end+1} = struct('NAME', 'Qualityfactor',   'UNIT', NO_ODL_UNIT, 'BYTES',  3, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Quality factor from 0-100.');   % TODO: Correct?
            ocl1{end+1} = struct('NAME', 'SAA',             'UNIT', 'degrees',   'BYTES',  7, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Solar aspect angle from x-axis of spacecraft.');
            ocl1{end+1} = struct('NAME', 'Illumination',    'UNIT', NO_ODL_UNIT, 'BYTES',  4, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sunlit probe indicator. 1 for sunlit, 0 for shadow, partial shadow otherwise.');
            ocl1{end+1} = struct('NAME', 'direction',       'UNIT', NO_ODL_UNIT, 'BYTES',  1, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sweep bias step direction. 1 for positive bias step, 0 for negative bias step.');
            % ----- (Changing from ocl1 to ocl2.) -----
            ocl2 = {};
            ocl2{end+1} = struct('NAME', 'old.Vsi',                'UNIT', 'V',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'old.Vx',                 'UNIT', 'V',         'DESCRIPTION', 'Spacecraft potential + Te from electron current fit. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'Vsg',                    'UNIT', 'V',         'DESCRIPTION', 'Spacecraft potential from gaussian fit to second derivative.');
            ocl2{end+1} = struct('NAME', 'sigma_Vsg',              'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for spacecraft potential from gaussian fit to second derivative.');
            ocl2{end+1} = struct('NAME', 'old.Tph',                'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron temperature. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'old.Iph0',               'UNIT', 'A',         'DESCRIPTION', 'Photosaturation current. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'Vb_lastnegcurrent',      'UNIT', 'V',         'DESCRIPTION', 'bias potential below zero current.');
            ocl2{end+1} = struct('NAME', 'Vb_firstposcurrent',     'UNIT', 'V',         'DESCRIPTION', 'bias potential above zero current.');
            ocl2{end+1} = struct('NAME', 'Vbinfl',                 'UNIT', 'V',         'DESCRIPTION', 'Bias potential of inflection point in current.');
            ocl2{end+1} = struct('NAME', 'dIinfl',                 'UNIT', 'A/V',       'DESCRIPTION', 'Derivative of current in inflection point.');
            ocl2{end+1} = struct('NAME', 'd2Iinfl',                'UNIT', 'A/V^2',     'DESCRIPTION', 'Second derivative of current in inflection point.');
            ocl2{end+1} = struct('NAME', 'Iph0',                   'UNIT', 'A',         'DESCRIPTION', 'Photosaturation current.');
            ocl2{end+1} = struct('NAME', 'Tph',                    'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron temperature.');
            ocl2{end+1} = struct('NAME', 'Vsi',                    'UNIT', 'V',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current.');
            ocl2{end+1} = struct('NAME',       'Vph_knee',         'UNIT', 'V',         'DESCRIPTION',                               'Potential at probe position from photoelectron current knee (gaussian fit to second derivative).');            
            ocl2{end+1} = struct('NAME', 'sigma_Vph_knee',         'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Potential at probe position from photoelectron current knee (gaussian fit to second derivative).');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME',       'Te_linear',        'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from linear fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_Te_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron temperature from linear fit to electron current.');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME',       'ne_linear',        'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron (plasma) density from linear fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_ne_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron (plasma) density from linear fit to electron current.');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME',       'ion_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of ion current fit as a function of absolute potential.');            
            ocl2{end+1} = struct('NAME', 'sigma_ion_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of absolute potential');
            ocl2{end+1} = struct('NAME',       'ion_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'e_slope',          'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_slope',          'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'e_intersect',      'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_intersect',      'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'ion_Vb_intersect', 'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_Vb_intersect', 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of ion current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME',       'e_Vb_intersect',   'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_Vb_intersect',   'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'Tphc',                   'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron cloud temperature (if applicable).');
            ocl2{end+1} = struct('NAME', 'nphc',                   'UNIT', 'cm^-3',     'DESCRIPTION', 'Photoelectron cloud density (if applicable).');
            ocl2{end+1} = struct('NAME',       'phc_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_phc_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME',       'phc_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_phc_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'ne_5eV',                 'UNIT', 'cm^-3',     'DESCRIPTION', 'Electron density from linear electron current fit, assuming electron temperature Te = 5 eV.');
            ocl2{end+1} = struct('NAME', 'ni_v_dep',               'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity.');
            ocl2{end+1} = struct('NAME', 'ni_v_indep',             'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate.');
            ocl2{end+1} = struct('NAME', 'v_ion',                  'UNIT', 'm/s',       'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate.');
            ocl2{end+1} = struct('NAME',       'Te_exp',           'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from exponential fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_Te_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron temperature from exponential fit to electron current.');
            ocl2{end+1} = struct('NAME',       'ne_exp',           'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron density derived from fit of exponential part of the thermal electron current.');  % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'sigma_ne_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron density derived from fit of exponential part of the thermal electron current.');  % New from commit 3dce0a0, 2014-12-16 or earlier.          
                        
            ocl2{end+1} = struct('NAME', 'Rsquared_linear',            'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current.');   % New from commit f89c62b, 2015-01-09 or earlier.
            ocl2{end+1} = struct('NAME', 'Rsquared_exp',               'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current.');   % New from commit f89c62b, 2015-01-09 or earlier.
            
            %ocl2{end+1} = struct('NAME',       'asm_Vsg',              'UNIT', 'V',         'DESCRIPTION', 'Spacecraft potential from gaussian fit to second derivative. Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'asm_sigma_Vsg',              'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Standard deviation of spacecraft potential from gaussian fit to second derivative. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'Vbar',              'UNIT', ODL_VALUE_UNKNOWN,    'DESCRIPTION', '');  % New from commit, aa33268 2015-03-26 or earlier.
            ocl2{end+1} = struct('NAME', 'sigma_Vbar',              'UNIT', ODL_VALUE_UNKNOWN,    'DESCRIPTION', '');  % New from commit, aa33268 2015-03-26 or earlier.
            
            ocl2{end+1} = struct('NAME', 'ASM_Iph0',                   'UNIT', 'A',         'DESCRIPTION', 'Assumed photosaturation current used (referred to) in the Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'ASM_Tph',                    'UNIT', 'eV',        'DESCRIPTION', 'Assumed photoelectron temperature used (referred to) in the Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Vsi',                    'UNIT', 'V',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME',       'asm_Vph_knee',         'UNIT', 'V',         'DESCRIPTION',                               'Potential at probe position from photoelectron current knee (gaussian fit to second derivative) with Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'asm_sigma_Vph_knee',         'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Potential at probe position from photoelectron current knee (gaussian fit to second derivative) with Fixed photoelectron current assumption.');    % New  from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME',       'asm_Te_linear',        'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron temperature from linear fit to electron current with Fixed photoelectron current assumption.');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME',       'asm_ne_linear',        'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron (plasma) density from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'sigma_asm_ne_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron (plasma) density from linear fit to electron current with Fixed photoelectron current assumption.');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME',       'asm_ion_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');            
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ion_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_e_slope',          'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_slope',          'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_e_intersect',      'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_intersect',      'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');            
            ocl2{end+1} = struct('NAME',       'asm_ion_Vb_intersect', 'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_Vb_intersect', 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');            
            ocl2{end+1} = struct('NAME',       'asm_e_Vb_intersect',   'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_Vb_intersect',   'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Tphc',                   'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron cloud temperature (if applicable). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_nphc',                   'UNIT', 'cm^-3',     'DESCRIPTION', 'Photoelectron cloud density (if applicable). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_phc_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_phc_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_phc_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_phc_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ne_5eV',                 'UNIT', 'cm^-3',     'DESCRIPTION', 'Electron density from linear electron current fit, assuming Te= 5eV. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ni_v_dep',               'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ni_v_indep',             'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate. Fixed photoelectron current assumption.');           
            ocl2{end+1} = struct('NAME', 'asm_v_ion',                  'UNIT', 'm/s',       'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_Te_exp',           'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from exponential fit to electron current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron temperature from exponential fit to electron current. Fixed photoelectron current assumption.');            
            ocl2{end+1} = struct('NAME',       'asm_ne_exp',           'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron density derived from fit of exponential part of the thermal electron current.');    % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_sigma_ne_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron density derived from fit of exponential part of the thermal electron current.');    % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Rsquared_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current. Fixed photoelectron current assumption.');   % New from commit f89c62b, 2015-01-09 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Rsquared_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current. Fixed photoelectron current assumption.');   % New from commit f89c62b, 2015-01-09 or earlier.
            
            ocl2{end+1} = struct('NAME', 'ASM_m_ion',      'BYTES', 3, 'UNIT', 'amu',               'DESCRIPTION', 'Assumed ion mass for all ions.');     % New from commit a56c578, 2015-01-22 or earlier.
            ocl2{end+1} = struct('NAME', 'ASM_Z_ion',      'BYTES', 2, 'UNIT', 'Elementary charge', 'DESCRIPTION', 'Assumed ion charge for all ions.');   % New from commit a56c578, 2015-01-22 or earlier.
            ocl2{end+1} = struct('NAME', 'ASM_v_ion',                  'UNIT', 'm/s',               'DESCRIPTION', 'Assumed ion ram speed in used in *_v_dep variables.');   % New from commit a56c578, 2015-01-22 or earlier. Earlier name: ASM_m_vram, ASM_vram_ion.
            ocl2{end+1} = struct('NAME',     'Vsc_ni_ne',              'UNIT', 'V',                 'DESCRIPTION', 'Spacecraft potential needed to produce identical ion (ni_v_indep) and electron (ne_linear) densities.');   % New from commit a56c578, 2015-01-22 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Vsc_ni_ne',              'UNIT', 'V',                 'DESCRIPTION', 'Spacecraft potential needed to produce identical ion (asm_ni_v_indep) and electron (asm_ne_linear) densities. Fixed photoelectron current assumption.');   % New from commit a56c578, 2015-01-22 or earlier.
            
            ocl2{end+1} = struct('NAME', 'Vsc_aion',                  'UNIT', 'V',      'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'ni_aion',                   'UNIT', 'cm^-3',  'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'v_aion',                    'UNIT', 'm/s',    'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Vsc_aion',              'UNIT', 'V',      'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_ni_aion',               'UNIT', 'cm^-3',  'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_v_aion',                'UNIT', 'm/s',    'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            %---------------------------------------------------------------------------------------------------
            % Removed from commit 3dce0a0, 2014-12-16, or earlier.
            %ocl2{end+1} = struct('NAME', 'asm_e_Vb_slope',         'UNIT', 'A/V',       'DESCRIPTION', 'Slope of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'asm_sigma_e_Vb_slope',   'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'asm_ion_Vb_slope',       'UNIT', 'A/V',       'DESCRIPTION', 'Slope of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'asm_sigma_ion_Vb_slope', 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'ion_Vb_slope',           'UNIT', 'A/V',       'DESCRIPTION', 'Slope of ion current fit as a function of bias potential ');
            %ocl2{end+1} = struct('NAME', 'sigma_ion_Vb_slope',     'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of bias potential');
            %ocl2{end+1} = struct('NAME', 'e_Vb_slope',             'UNIT', 'A/V',       'DESCRIPTION', 'Slope of linear electron current fit as a function of bias potential ');
            %ocl2{end+1} = struct('NAME', 'sigma_e_Vb_slope',       'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of bias potential ');
            %---------------------------------------------------------------------------------------------------
            
            %ocl2{end+1} = struct('NAME', 'asm_Vbar',                'UNIT', ODL_VALUE_UNKNOWN,    'DESCRIPTION', '');  % New from commit, aa33268 2015-03-26 or earlier.
            %ocl2{end+1} = struct('NAME', 'asm_sigma_Vbar',          'UNIT', ODL_VALUE_UNKNOWN,    'DESCRIPTION', '');  % New from commit, aa33268 2015-03-26 or earlier.
            
            ocl2{end+1} = struct('NAME',           'Te_exp_belowVknee', 'UNIT', 'eV',    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',     'sigma_Te_exp_belowVknee', 'UNIT', 'eV',    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',           'ne_exp_belowVknee', 'UNIT', 'cm^-3', 'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',     'sigma_ne_exp_belowVknee', 'UNIT', 'cm^-3', 'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',       'asm_Te_exp_belowVknee', 'UNIT', 'eV',    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_exp_belowVknee', 'UNIT', 'eV',    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',       'asm_ne_exp_belowVknee', 'UNIT', 'cm^-3', 'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ne_exp_belowVknee', 'UNIT', 'cm^-3', 'DESCRIPTION', '');

            for i_oc = 1:length(ocl2)
                if ~isfield(ocl2{i_oc}, 'BYTES')
                    ocl2{i_oc}.BYTES = 14;
                end
                ocl2{i_oc}.DATA_TYPE = 'ASCII_REAL';
            end
            LBL_data.OBJTABLE.OBJCOL_list = [ocl1, ocl2];
            clear   ocl1 ocl2
            
            TAB_LBL_inconsistency_policy = AxS_TAB_LBL_inconsistency_policy;   % NOTE: Different policy for A?S.LBL files.
        
            
            
        elseif  strcmp(an_tabindex{i,7},'best_estimates')    %%%%%%%%%%%% BEST ESTIMATES FILE %%%%%%%%%%%%
            
            
            
            MISSING_CONSTANT = -1000;    % NOTE: This constant must be reflected in the corresponding section in best_estimates!!!
            LBL_data.OBJTABLE = [];
            LBL_data.OBJTABLE.DESCRIPTION = sprintf('BEST ESTIMATES OF PHYSICAL VALUES FROM MODEL FITTED ANALYSIS.');   % Bad description? To specific?
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION',  'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl{end+1} = struct('NAME', 'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION',  'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl{end+1} = struct('NAME', 'QUALITY',            'DATA_TYPE', 'ASCII_REAL', 'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');
            ocl{end+1} = struct('NAME', 'npl',                'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'CM**-3',    'MISSING_CONSTANT', MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of plasma number density.');
            ocl{end+1} = struct('NAME', 'Te',                 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'eV',        'MISSING_CONSTANT', MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of electron temperature.');
            ocl{end+1} = struct('NAME', 'Vsc',                'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'V',         'MISSING_CONSTANT', MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of spacecraft potential.');
            ocl{end+1} = struct('NAME', 'Probe_number',       'DATA_TYPE', 'ASCII_REAL', 'BYTES',  1, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Probe number. 1 or 2.');
            ocl{end+1} = struct('NAME', 'Direction',          'DATA_TYPE', 'ASCII_REAL', 'BYTES',  1, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Sweep bias step direction. 1 for positive bias step, 0 for negative bias step.');
            ocl{end+1} = struct('NAME', 'Illumination',       'DATA_TYPE', 'ASCII_REAL', 'BYTES',  4, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Sunlit probe indicator. 1 for sunlit, 0 for shadow, partial shadow otherwise.');
            ocl{end+1} = struct('NAME', 'Sweep_group_number', 'DATA_TYPE', 'ASCII_REAL', 'BYTES',  5, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', ...
                ['Number signifying which group of sweeps the data comes from. ', ...
                 'Groups of sweeps are formed for the purpose of deriving/selecting values to be used in best estimates. ', ...
                 'All sweeps with the same group number are almost simultaneous. For every type of best estimate, at most one is chosen from each group. ', ...
                 'The group number is included mostly for debugging purposes.']);  % NOTE: Causes trouble by making such a long line in LBL file?!!
            LBL_data.OBJTABLE.OBJCOL_list = ocl;
            clear   ocl

            
            
        else
            
            fprintf(1, 'Error, bad identifier in an_tabindex{%i,7}',i);
            
        end
        
        
        
        createLBL_create_OBJTABLE_LBL_file(an_tabindex{i,1}, LBL_data, TAB_LBL_inconsistency_policy);
        clear   LBL_data   TAB_LBL_inconsistency_policy
               
        
        
    end   % for 
end     % if

warning(warnings_settings)
fprintf(1, '%s: %.0f s (elapsed wall time)\n', mfilename, etime(clock, t_start));
