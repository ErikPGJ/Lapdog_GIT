%
% Writes the first list of variables (key-value pairs) to an LBL file, before the OBJECT TABLE etc.
%
% NOTE: Always interprets kvl.value{i} as (matlab) string, not number.
% NOTE: Always prints exact string, without adding quotes.
%
%
function createLBL_write_LBL_header(fid, kvl)   % kvl = key-value list
% PROPOSAL: Merge with createLBL_writeObjectTable.
%       PRO: Can design LBL filename and path.
%       PRO: Can open close & close LBL file.
%       PRO: Can set FILE_NAME (LBL file), ^TABLE (TAB file), RECORD_BYTES (TAB file size),
%       PRO: Can set PRODUCT_ID?!!  Rosetta archive conventions specify that should be based on filename without extension.
% PROPOSAL: Take parameter TAB_file_path ==> Set RECORD_BYTES (file size), ^TABLE, (RECORDS?!!)
%
% PROPOSAL: Separate parameter for (overwrite) values for e.g. PRODUCT_TYPE, PROCESSING_LEVEL_ID and other values which are the same for all files.
%   CON: Could/should be part of kvl.
%   CON: Should sometimes overwrite a default list of kvl, sometimes complement it (merge).
% PROPOSAL: Set which keywords that should have quoted values or not.
% PROPOSAL: Error-check that all keys are unique.
% PROPOSAL: Should set keywords that apply to all LBL/CAT files (not just OBJECT=TABLE).
%    Ex: PDS_VERSION_ID
% PROPOSAL: Should require keywords that apply to all LBL/CAT files (not just OBJECT=TABLE).
    
    main_INTERNAL(fid, kvl)
    
    function main_INTERNAL(fid, kvl)

        % PROPOSAL: Order by groups.
        %   Ex: General ODL/PDS. Mission_specific.
        general_key_order_list = { ...
            'PDS_VERSION_ID', ...    % PDS standard requires this to be first, I think.
            'RECORD_TYPE', ...
            'RECORD_BYTES', ...
            'FILE_RECORDS', ...
            'FILE_NAME', ...
            '^TABLE', ...
            'DATA_SET_ID', ...
            'DATA_SET_NAME', ...
            'DATA_QUALITY_ID', ...
            'MISSION_ID', ...
            'MISSION_NAME', ...
            'MISSION_PHASE_NAME', ...
            'PRODUCER_INSTITUTION_NAME', ...
            'PRODUCER_ID', ...
            'PRODUCER_FULL_NAME', ...
            'LABEL_REVISION_NOTE', ...
            'PRODUCT_ID', ...
            'PRODUCT_TYPE', ...
            'PRODUCT_CREATION_TIME', ...
            'INSTRUMENT_HOST_ID', ...
            'INSTRUMENT_HOST_NAME', ...
            'INSTRUMENT_NAME', ...
            'INSTRUMENT_ID', ...
            'INSTRUMENT_TYPE', ...
            'INSTRUMENT_MODE_ID', ...
            'INSTRUMENT_MODE_DESC', ...
            'TARGET_NAME', ...
            'TARGET_TYPE', ...
            'PROCESSING_LEVEL_ID', ...
            'START_TIME', ...
            'STOP_TIME', ...
            'SPACECRAFT_CLOCK_START_COUNT', ...
            'SPACECRAFT_CLOCK_STOP_COUNT', ...
            'DESCRIPTION'};
        
        ROSETTA_key_order_list = { ...
            'ROSETTA:LAP_TM_RATE', ...
            'ROSETTA:LAP_BOOTSTRAP', ...
            ...
            'ROSETTA:LAP_FEEDBACK_P1', ...
            'ROSETTA:LAP_P1_ADC20', ...
            'ROSETTA:LAP_P1_ADC16', ...
            'ROSETTA:LAP_P1_RANGE_DENS_BIAS', ...
            'ROSETTA:LAP_P1_STRATEGY_OR_RANGE', ...
            'ROSETTA:LAP_P1_RX_OR_TX', ...
            'ROSETTA:LAP_P1_ADC16_FILTER', ...
            'ROSETTA:LAP_IBIAS1', ...
            'ROSETTA:LAP_P1_BIAS_MODE', ...
            'ROSETTA:LAP_P1_INITIAL_SWEEP_SMPLS', ...
            'ROSETTA:LAP_P1_SWEEP_PLATEAU_DURATION', ...
            'ROSETTA:LAP_P1_SWEEP_STEPS', ...
            'ROSETTA:LAP_P1_SWEEP_START_BIAS', ...
            'ROSETTA:LAP_P1_SWEEP_FORMAT', ...
            'ROSETTA:LAP_P1_SWEEP_RESOLUTION', ...
            'ROSETTA:LAP_P1_SWEEP_STEP_HEIGHT', ...
            ...
            'ROSETTA:LAP_FEEDBACK_P2', ...
            'ROSETTA:LAP_P2_ADC20', ...
            'ROSETTA:LAP_P2_ADC16', ...
            'ROSETTA:LAP_P2_RANGE_DENS_BIAS', ...
            'ROSETTA:LAP_P2_STRATEGY_OR_RANGE', ...
            'ROSETTA:LAP_P2_RX_OR_TX', ...
            'ROSETTA:LAP_P2_ADC16_FILTER', ...
            'ROSETTA:LAP_IBIAS2', ...
            'ROSETTA:LAP_P2_BIAS_MODE', ...
            'ROSETTA:LAP_P2_INITIAL_SWEEP_SMPLS', ...
            'ROSETTA:LAP_P2_SWEEP_PLATEAU_DURATION', ...
            'ROSETTA:LAP_P2_SWEEP_STEPS', ...
            'ROSETTA:LAP_P2_SWEEP_START_BIAS', ...
            'ROSETTA:LAP_P2_SWEEP_FORMAT', ...
            'ROSETTA:LAP_P2_SWEEP_RESOLUTION', ...
            'ROSETTA:LAP_P2_SWEEP_STEP_HEIGHT', ...
            ...
            'ROSETTA:LAP_P1P2_ADC20_STATUS', ...
            'ROSETTA:LAP_P1P2_ADC20_MA_LENGTH', ...
            'ROSETTA:LAP_P1P2_ADC20_DOWNSAMPLE'
            };
        key_order_list = [general_key_order_list, ROSETTA_key_order_list];
        
        % Give error if encountering any of these keys.
        % Useful for obsoleted keys that should not exist anymore.
        forbidden_keys = { ...
            'ROSETTA:LAP_INITIAL_SWEEP_SMPLS', ...
            'ROSETTA:LAP_SWEEP_PLATEAU_DURATION', ...
            'ROSETTA:LAP_SWEEP_STEPS', ...
            'ROSETTA:LAP_SWEEP_START_BIAS', ...
            'ROSETTA:LAP_SWEEP_FORMAT', ...
            'ROSETTA:LAP_SWEEP_RESOLUTION', ...
            'ROSETTA:LAP_SWEEP_STEP_HEIGHT'};

        

        % Log message
        %LBL_file_path = fopen(fid);   % Find name of file. (Does NOT open the file.)
        %fprintf(1, 'Write LBL header %s\n', LBL_file_path);

        
        
        %===========================================================================
        % Put key-value pairs in certain order.
        % -------------------------------------
        % Look for specified keys and for those found, put them in the given order.
        % NOTE: This is done for at least two reasons:
        % 1) to make LBL files more "beautiful" (e.g. P1 before P2 keywords,
        %    non-ROSETTA before ROSETTA keywords), and
        % 2) to ensure that LBL keywords are always in approximately the same order.
        %    This is useful when comparing datasets to ensure that a modified/updated
        %    lapdog code produces only the desired changes to LBL files.
        %===========================================================================
        kvl = KVPL_order_by_key_list_INTERNAL(kvl, key_order_list);        
        
        %============================================================
        % Check that there are no forbidden keys.
        % To ensure that obsoleted keywords are not used by mistake.
        %============================================================
        for i=1:length(forbidden_keys)            
            if any(strcmp(forbidden_keys{i}, kvl.keys))
                error(sprintf('Trying to write LBL file header with explicitly forbidden LBL keyword "%s". This indicates that the code has previously failed to substitute these keywords for new ones.', forbidden_keys{i}))
            end
        end


        % Parameter error check.
        if length(unique(kvl.keys)) ~= length(kvl.keys)
            error('Found doubles among the keys/ODL attribute names.')
        end
        if isempty(kvl.keys)                    % Not sure why checks for this specifically. Previously checked before calculating max_key_length.
            error('kvl.keys is empty.')
        end
        
        max_key_length = max(cellfun(@length, kvl.keys));
        
        for j = 1:length(kvl.keys) % Print header of analysis file
            key   = kvl.keys{j};
            value = kvl.values{j};
            
            if ~ischar(value)
                error(sprintf('(key-) value is not a MATLAB string:\n key = "%s", fopen(fid) = "%s"', key, fopen(fid)))
            end
            
            fprintf(fid, ['%-', num2str(max_key_length), 's = %s\r\n'], key, value);
        end
        
    end   % function



    % =============================================================================================
    
    
    
    % Order the key-value pairs according to a list of keys.
    % Remaining key-value pairs will be added at the end in their previous internal order.
    %
    % CURRENT VERSION: Does not assume any relationship between kvl.keys and key_order_list
    % (either may contain elements not existing in the other).
    %
    function kvl = KVPL_order_by_key_list_INTERNAL(kvl, key_order_list)
        % Require that all key_order_list are a subset of kvl.keys?!!
        % Require that kvl.keys are a subset of key_order_list?
        % Require that kvl.keys and key_order_list are identical (except for order of elements)?!!
        
        if length(unique(key_order_list)) ~= length(key_order_list)
            error('key_order_list contains multiple identical keys.')
        end
        
        % Använd KVPL_read_value? Ger fel om inte hittar key.
        i_ordered = [];
        
        for i_kol = 1:length(key_order_list)
            i_kv = find(strcmp(key_order_list{i_kol}, kvl.keys));
            if length(i_kv) == 1
                i_ordered(end+1, 1) = i_kv;
                %else if length(i_kv) > 1
                %    error('Multiple identical key in kvl.')
            end
        end
        
        % Find indices into kvl.keys that are not already in i_ordered.
        % NOTE: Want to keep the original order.
        b = ones(size(kvl.keys));
        b(i_ordered) = 0;
        i_remaining = find(b);
        
        i_order_tot = [i_ordered; i_remaining];
        
        % Internal consistency check. Can be disabled.
        if (length(i_order_tot) ~= length(kvl.keys)) || any(sort(i_order_tot) ~= [1:length(kvl.keys)]')
            error('ERROR: Likely bug in algorithm');
        end
        
        kvl.keys   = kvl.keys  (i_order_tot);
        kvl.values = kvl.values(i_order_tot);        
    end

end
