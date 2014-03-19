%createLBL.m

%%DATAFILE .LBL FILES

if(~isempty(tabindex));
    len= length(tabindex(:,3));
    
    

    
    for(i=1:len)
        
        %tabindex cell array = {tab file name, first index number of batch,
        % UTC time of last row, S/C time of last row, row counter}
        %    units: [cell array] =  {[string],[double],[string],[float],[integer]
        
        % Write label file:
        tname = tabindex{i,2};
        lname=strrep(tname,'TAB','LBL');

        
        [fp,errmess] = fopen(index(tabindex{i,3}).lblfile,'r'); %Problematic for indexes created in indexcorr (Files split at midnight)
        tempfp = textscan(fp,'%s %s','Delimiter','=');
        fclose(fp);
        
        dl = fopen(strrep(tabindex{i,1},'TAB','LBL'),'w');
        
        
        %This version is not very pretty, but efficient. It reads the first LBL
        %file of the mode in the batch and edits line for line. Sometimes
        %copying some lines and pasting them in the correct position, from
        %bottom to top (to prevent unwanted overwrites).
        
        fileinfo = dir(tabindex{i,1});
        tempfp{1,2}{3,1} = sprintf('%d',fileinfo.bytes);
        tempfp{1,2}{4,1} = sprintf('%d',tabindex{i,6});
        tempfp{1,2}{5,1} = lname;
            tempfp{1,2}{6,1} = tname;
         
        tempfp{1,2}{7,1}= strrep(tempfp{1,2}{7,1},sprintf('-3-%s-CALIB',shortphase),sprintf('-4-%s-DERIV',shortphase));
       tempfp{1,2}{8,1}=   strrep(tempfp{1,2}{8,1},sprintf('3 %s CALIB',shortphase),sprintf('4 %s DERIV',shortphase));
   
        tempfp{1,2}{14,1}=producershortname;
        tempfp{1,2}{15,1}=sprintf('"%s"',producerfullname);
       
        
        
        tempfp{1,2}{16,1} = sprintf('"%s, %s, %s"',lbltime,lbleditor,lblrev);
        tempfp{1,2}(17:18) = [];
        tempfp{1,1}(17:18) =[]; % should be deleted?
        tempfp{1,2}{17,1} = datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF'); %product creation time
        tempfp{1,2}{27,1} = '"4"'; %% processing level ID
        tempfp{1,2}{28,1} = index(tabindex{i,3}).t0str; %UTC start time
        tempfp{1,2}{29,1} = tabindex{i,4};             % UTC stop time
        tmpsct0 = index(tabindex{i,3}).sct0str(5:end-1);
        tempfp{1,2}{30,1} = tmpsct0;                    %% sc start time
        tempfp{1,2}{31,1} = sprintf('%16.6f',tabindex{i,5}); %% sc stop time
        tempfp{1,2}{54,1} = sprintf('%i',tabindex{i,6}); %% rows
        
        a =    tname(30);
        if (tname(30)=='S') % special format for sweep files...
            if (tname(28)=='B')
                
                tempfp{1,2}{55,1} = '2'; %number of rows
                tempfp{1,2}{56,1} = '36';% ROW_BYTES
                
                
                tempfp{1,2}(74:82) = [];  %remove Current column
                tempfp{1,1}(74:82) = [];
                tempfp{1,2}(58:64) = [];  %remove UTC column
                tempfp{1,1}(58:64) = [];
                
                
                
                
                tempfp{1,2}{59,1} = 'SWEEP_TIME';
                tempfp{1,2}{62,1} = 'ASCII_REAL';
                tempfp{1,2}{60,1} = '1';
                tempfp{1,2}{61,1} = '16';
                tempfp{1,2}{63,1} = 'SECONDS';
                tempfp{1,2}{64,1} = '"F16.6"';
                tempfp{1,2}{65,1} = '"LAPSED TIME (S/C CLOCK TIME) FROM FIRST SWEEP MEASUREMENT SSSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"';
                
                tempfp{1,2}{70,1} = '25';
                
            elseif (tname(28)=='I')
                tempfp{1,2}(90:98) = tempfp{1,2}(74:82); % move sweep current column
                tempfp{1,1}(90:98) = tempfp{1,1}(74:82);
                tempfp{1,2}(81:89) = tempfp{1,2}(65:73); %move S/C time column twice
                tempfp{1,1}(81:89) = tempfp{1,1}(65:73);
                tempfp{1,2}(72:80) = tempfp{1,2}(65:73);
                tempfp{1,1}(72:80) = tempfp{1,1}(65:73);
                tempfp{1,2}(65:71) = tempfp{1,2}(58:64); %copy UTC time column
                tempfp{1,1}(65:71) = tempfp{1,1}(58:64);
                
                %edit some lines
                tempfp{1,2}{55,1} = sprintf('%i',tabindex{i,7});  %number of columns
                tempfp{1,2}{56,1} = '3212'; %row byte size
                tempfp{1,2}{69,1} = '26';   %second column start byte
                tempfp{1,2}{74,1} = '56';   %third column start byte
                tempfp{1,2}{83,1} = '74';   %fourth column start byte
                tempfp{1,2}{93,1} = '92';   %fifth column start byte
                tempfp{1,2}{59,1} = '"SWEEP_START_TIME_UTC"';
                tempfp{1,2}{63,1} = '"START TIME OF SWEEP DATA ROW (UTC)"';
                tempfp{1,2}{66,1} = '"SWEEP_END_TIME_UTC"';
                tempfp{1,2}{70,1} = '"END TIME OF SWEEP DATA ROW (UTC)"';
                tempfp{1,2}{73,1} = '"SWEEP_START_TIME_OBT"';
                tempfp{1,2}{79,1} = '"START TIME OF SWEEP DATA ROW (SPACECRAFT ONBOARD TIME)"';
                tempfp{1,2}{82,1} = '"SWEEP_END_TIME_OBT"';
                tempfp{1,2}{88,1} = '"END TIME OF SWEEP DATA ROW (SPACECRAFT ONBOARD TIME)"';
                tempfp{1,2}{90,1} = 'ROW';
                tempfp{1,2}{97,1} = sprintf('"FULL MEASURED CALIBRATED CURRENT SWEEP COLUMNS 5-%i)"',tabindex{i,7});
                tempfp{1,2}{98,1} = 'ROW';
                tempfp{1,1}{99,1} = 'END_OBJECT';
                tempfp{1,2}{99,1} = 'TABLE';
                tempfp{1,1}{100,1} = 'END'; % Ends file, this line is never printed, but we need something on last row
                %tempfp{1,2}{100,1} = '';%
                
            else
                fprintf(1,'  BAD IDENTIFIER FOUND, %s\n',tname);
            end
        end
        
        for (i=1:length(tempfp{1,1})-1) %skip last row
            fprintf(dl,'%s=%s\n',tempfp{1,1}{i,1},tempfp{1,2}{i,1});
        end
        
        fprintf(dl,'END');% Ends file
        fclose(dl);
        
    end
    
end

%% BLOCK LIST .LBL FILES

if(~isempty(blockTAB));
    len=length(blockTAB(:,3));
    for(i=1:len)
        
        tname = blockTAB{i,2};
        lname=strrep(tname,'TAB','LBL');
        bl = fopen(strrep(blockTAB{i,1},'TAB','LBL'),'w');
        
        fprintf(bl,'PDS_VERSION_ID = PDS3\n');
        fprintf(bl,'RECORD_TYPE = FIXED_LENGTH\n');
        fileinfo = dir(blockTAB{i,1});
        fprintf(bl,'RECORD_BYTES = %d\n',fileinfo.bytes);
        fprintf(bl,'FILE_RECORDS = %d\n',blockTAB{i,3});
        fprintf(bl,'FILE_NAME = "%s"\n',lname);
        fprintf(bl,'^TABLE = "%s"\n',tname);
        
        fprintf(bl,'DATA_SET_ID = "%s"\n', strrep(datasetid,sprintf('-3-%s-CALIB',shortphase),sprintf('-4-%s-DERIV',shortphase)));
        fprintf(bl,'DATA_SET_NAME = "%s"\n',strrep(datasetname,sprintf('3 %s CALIB',shortphase),sprintf('4 %s DERIV',shortphase)));
        fprintf(bl,'DATA_QUALITY_ID = 1\n');
        fprintf(bl,'MISSION_ID = ROSETTA\n');
        fprintf(bl,'MISSION_NAME = "INTERNATIONAL ROSETTA MISSION"\n');
        fprintf(bl,'MISSION_PHASE_NAME = "%s"\n',missionphase);
        fprintf(bl,'PRODUCER_INSTITUTION_NAME = "SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"\n');
        fprintf(bl,'PRODUCER_ID = %s\n',producershortname);
        fprintf(bl,'PRODUCER_FULL_NAME = "%s"\n',producerfullname);
        fprintf(bl,'LABEL_REVISION_NOTE = "%s, %s, %s"\n',lbltime,lbleditor,lblrev);
        mm = length(tname);
        fprintf(bl,'PRODUCT_ID = "%s"\n',tname(1:(mm-4)));
        fprintf(bl,'PRODUCT_TYPE = "EDR"\n');  % No idea what this means...
        fprintf(bl,'PRODUCT_CREATION_TIME = %s\n',datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF'));
        fprintf(bl,'INSTRUMENT_HOST_ID = RO\n');
        fprintf(bl,'INSTRUMENT_HOST_NAME = "ROSETTA-ORBITER"\n');
        fprintf(bl,'INSTRUMENT_NAME = "ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"\n');
        fprintf(bl,'INSTRUMENT_ID = RPCLAP\n');
        fprintf(bl,'INSTRUMENT_TYPE = "PLASMA INSTRUMENT"\n');
        fprintf(bl,'TARGET_NAME = "%s"\n',targetfullname);
        fprintf(bl,'TARGET_TYPE = "%s"\n',targettype);
        fprintf(bl,'PROCESSING_LEVEL_ID = %d\n',4);
        fprintf(bl,'INTERCHANGE_FORMAT = ASCII\n');
        fprintf(bl,'ROWS = %d\n',blockTAB{i,3});
        fprintf(bl,'COLUMNS = 3\n');
        fprintf(bl,'ROW_BYTES = 59\n');
        fprintf(bl,'DESCRIPTION = "BLOCKLIST DATA. START & STOP TIME OF MACROBLOCK AND MACROID."\n');
        
        
        
        fprintf(bl,'OBJECT = COLUMN\n');
        fprintf(bl,'NAME = TIME_UTC\n');
        fprintf(bl,'DATA_TYPE = TIME\n');
        fprintf(bl,'START_BYTE = 1\n');
        fprintf(bl,'BYTES = 23\n');
        fprintf(bl,'UNIT = SECONDS\n');
        fprintf(bl,'DESCRIPTION = "START TIME OF MACRO BLOCK YYYY-MM-DD HH:MM:SS.sss"\n');
        fprintf(bl,'END_OBJECT  = COLUMN\n');
        
        fprintf(bl,'OBJECT = COLUMN\n');
        fprintf(bl,'NAME = TIME_UTC\n');
        fprintf(bl,'DATA_TYPE = TIME\n');
        fprintf(bl,'START_BYTE = 24\n');
        fprintf(bl,'BYTES = 23\n');
        fprintf(bl,'UNIT = SECONDS\n');
        fprintf(bl,'DESCRIPTION = "END TIME OF MACRO BLOCK YYYY-MM-DD HH:MM:SS.sss"\n');
        fprintf(bl,'END_OBJECT  = COLUMN\n');
        
        fprintf(bl,'OBJECT = COLUMN\n');
        fprintf(bl,'NAME = MACRO_ID\n');
        fprintf(bl,'DATA_TYPE = ASCII_REAL\n');
        fprintf(bl,'START_BYTE = 48\n');
        fprintf(bl,'BYTES = 3\n');
        fprintf(bl,'DESCRIPTION = "MACRO IDENTIFICATION NUMBER"\n');
        fprintf(bl,'END_OBJECT  = COLUMN\n');
        fprintf(bl,'END');
        fclose(bl);
        
    end
    
end

%% Derived results .LBL files


if(~isempty(an_tabindex));
    len=length(an_tabindex(:,1));
    
    for(i=1:len)

%%some need-to-know things  
        tname = an_tabindex{i,2};
        lname=strrep(tname,'TAB','LBL');

            mode = tname(end-6:end-4);
            Pnum = tname(end-5);


%%%%%HEADER 
	%steal header(line 1:55) from existing LBL file, edit smaller things and write the rest customised by analysis file type.
	 [fp,errmess] = fopen(index(an_tabindex{i,3}).lblfile,'r'); 
        tempfp = textscan(fp,'%s %s','Delimiter','=');
        fclose(fp);



    
	fileinfo = dir(an_tabindex{i,1});
        tempfp{1,2}{3,1} = sprintf('%d',fileinfo.bytes);
        tempfp{1,2}{4,1} = sprintf('%d',an_tabindex{i,4};
        tempfp{1,2}{5,1} = lname;
        tempfp{1,2}{6,1} = tname;
        tempfp{1,2}{17,1} = datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF'); %product creation time


%28START_TIME =2007-11-07T02:32:42.861                                        
%29STOP_TIME =2007-11-07T23:59:59.141888
%30SPACECRAFT_CLOCK_START_COUNT =153023530.1600
%31SPACECRAFT_CLOCK_STOP_COUNT =153100766.291081

   
  	  al = fopen(strrep(an_tabindex{i,1},'TAB','LBL'),'w');

%%% TAB FILE TYPE CUSTOMISATION

	  if strcmp(an_tabindex{i,7},'downsample') %%%%%%%%DOWNSAMPLED FILE%%%%%%%%%%%%%%%

		 tempfp{1,2}{32,1} = sprintf('"%s SECONDS DOWNSAMPLED MEASUREMENT"',lname(end-10:end-9));

	           %%%%%PRINT HEADER
		 for (i=1:55) %print header of analysis file 
  	     	     fprintf(al,'%s=%s\n',tempfp{1,1}{i,1},tempfp{1,2}{i,1});
       		 end
		%% Customise the rest!



 	       fprintf(al,'OBJECT = TABLE\n');
 	       fprintf(al,'INTERCHANGE_FORMAT = ASCII\n');
      	  fprintf(al,'ROWS = %d\n',an_tabindex{i,4});
    	    fprintf(al,'COLUMNS = %d\n',an_tabindex{i,5});

	    fprintf(al,'ROW_BYTES = 110\n');   %%row_bytes here!!!

            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = TIME_UTC\n');
            fprintf(al,'DATA_TYPE = TIME\n');
            fprintf(al,'START_BYTE = 1\n');
            fprintf(al,'BYTES = 23\n');
            fprintf(al,'UNIT = SECONDS\n');
            fprintf(al,'DESCRIPTION = "UTC TIME YYYY-MM-DD HH:MM:SS.FFF"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = OBT_TIME\n');
            fprintf(al,'START_BYTE = 26\n');
            fprintf(al,'BYTES = 16\n'); %
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'UNIT = SECONDS\n');
            fprintf(al,'DESCRIPTION = "SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
       
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_CURRENT\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 45\n');
            fprintf(al,'BYTES = 13\n');
            fprintf(al,'UNIT = AMPERE\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "AVERAGED CURRENT"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
         
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_CURRENT_STDDEV\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 61\n');
            fprintf(al,'BYTES = 13\n');
            fprintf(al,'UNIT = AMPERE\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "CURRENT STANDARD DEVIATION"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
          
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_VOLT\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 77\n');
            fprintf(al,'BYTES = 13\n');
            fprintf(al,'UNIT = VOLT\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "AVERAGED MEASURED VOLTAGE"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_VOLT_STDDEV\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 93\n');
            fprintf(al,'BYTES = 13\n');
            fprintf(al,'UNIT = VOLT\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "VOLTAGE STANDARD DEVIATION"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'END_OBJECT  = TABLE\n');
            fprintf(al,'END');
            fclose(al);



	elseif strcmp(an_tabindex{i,7},'spectra') %%%%%%%%%%%%%%%%SPECTRA FILE%%%%%%%%%%


		 tempfp{1,2}{32,1} = sprintf('"%s PSD SPECTRA OF HIGH FREQUENCY MEASUREMENT"',lname(end-10:end-9));

	           %%%%%PRINT HEADER
		 for (i=1:66) %print header of analysis file 
  	     	     fprintf(al,'%s=%s\n',tempfp{1,1}{i,1},tempfp{1,2}{i,1});
       		 end
		%% Customise the rest!


        fprintf(al,'OBJECT = TABLE\n');
        fprintf(al,'INTERCHANGE_FORMAT = ASCII\n');
        fprintf(al,'ROWS = %d\n',an_tabindex{i,4});
        fprintf(al,'COLUMNS = %d\n',an_tabindex{i,5});


	elseif  strcmp(an_tabindex{i,7},'frequency') %%%%%%%%%%%%FREQUENCY FILE%%%%%%%%%

		 tempfp{1,2}{32,1} = sprintf('"%s FREQUENCY LIST OF PSD SPECTRA FILE"',lname(end-10:end-9));

	           %%%%%PRINT HEADER
		 for (i=1:66) %print header of analysis file 
  	     	     fprintf(al,'%s=%s\n',tempfp{1,1}{i,1},tempfp{1,2}{i,1});
       		 end
		%%%%% Customise the rest!


       	    fprintf(al,'OBJECT = TABLE\n');
       	    fprintf(al,'INTERCHANGE_FORMAT = ASCII\n');
       	    fprintf(al,'ROWS = %d\n',an_tabindex{i,4});
     	    fprintf(al,'COLUMNS = %d\n',an_tabindex{i,5});


	    fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = FREQUENCY LIST\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 0\n');
            fprintf(al,'BYTES = 13\n');
            fprintf(al,'UNIT = kHz\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "FREQUENCY LIST FOR CORRESPONDING PSD SPECTRA FILE"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');

	    fprintf(al,'END_OBJECT  = TABLE\n');
            fprintf(al,'END');
            fclose(al);

	else
	'error'
	fclose(al);
	end
        
        
end
end




if(~isempty(an_tabindex));
    len=length(an_tabindex(:,1));
    
    for(i=1:len)
        
        %tabindex cell array = {tab file name, first index number of batch,
        % UTC time of last row, S/C time of last row, row counter}
        %    units: [cell array] =  {[string],[double],[string],[float],[integer]
        
        % Write label file:
        
        
        %[fp,errmess] = fopen(index(an_tabindex{i,3}).lblfile,'r'); %Problematic for indices created in indexcorr (Files split at midnight)
        %tempfp = textscan(fp,'%s %s','Delimiter','=');
        %fclose(fp);
        
        tname = an_tabindex{i,2};
      %  tabi0 = str2double(an_tabindex{i,6}(1:2)); %%tabindex index of first tabfilein
      %  tabi1 = str2double(an_tabindex{i,6}(end-1:end)); %%tabindex of last tabfile
        lname=strrep(tname,'TAB','LBL');
        
        al = fopen(strrep(an_tabindex{i,1},'TAB','LBL'),'w');
        
        
        fprintf(al,'PDS_VERSION_ID = PDS3\n');
        fprintf(al,'RECORD_TYPE = FIXED_LENGTH\n');
        fileinfo = dir(an_tabindex{i,1});
        fprintf(al,'RECORD_BYTES = %d\n',fileinfo.bytes);
        fprintf(al,'FILE_RECORDS = %d\n',an_tabindex{i,4});
        fprintf(al,'FILE_NAME = "%s"\n',lname);
        fprintf(al,'^TABLE = "%s"\n',tname);
        fprintf(al,'DATA_SET_ID = "%s"\n',datasetid);
        fprintf(al,'DATA_SET_NAME = "%s"\n',datasetname);
        fprintf(al,'DATA_QUALITY_ID = 1\n');
        fprintf(al,'MISSION_ID = ROSETTA\n');
        fprintf(al,'MISSION_NAME = "INTERNATIONAL ROSETTA MISSION"\n');
        fprintf(al,'MISSION_PHASE_NAME = "%s"\n',missionphase);
        fprintf(al,'PRODUCER_INSTITUTION_NAME = "SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"\n');
        fprintf(al,'PRODUCER_ID = %s\n',producershortname);
        fprintf(al,'PRODUCER_FULL_NAME = "%s"\n',producerfullname);
        fprintf(al,'LABEL_REVISION_NOTE = "%s, %s, %s"\n',lbltime,lbleditor,lblrev);
        mm = length(tname);
        fprintf(al,'PRODUCT_ID = "%s"\n',tname(1:(mm-4)));
        fprintf(al,'PRODUCT_TYPE = "EDR"\n');  % No idea what this means...
        fprintf(al,'PRODUCT_CREATION_TIME = %s\n',datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF'));
        fprintf(al,'INSTRUMENT_HOST_ID = RO\n');
        fprintf(al,'INSTRUMENT_HOST_NAME = "ROSETTA-ORBITER"\n');
        fprintf(al,'INSTRUMENT_NAME = "ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"\n');
        fprintf(al,'INSTRUMENT_ID = RPCLAP\n');
        fprintf(al,'INSTRUMENT_TYPE = "PLASMA INSTRUMENT"\n');
        fprintf(al,'TARGET_NAME = "%s"\n',targetfullname);
        fprintf(al,'TARGET_TYPE = "%s"\n',targettype);
        fprintf(al,'PROCESSING_LEVEL_ID = %d\n',4);
        
        %looks messy, but I'm finding the first original index used in this
        %file, and outputting it's start time, as well as the index of the
        %last file used, to output the stop time. There are easier ways, but
        %not as accurate.

      %  fprintf(al,'START_TIME  = %s\n',index(tabindex{tabi0,3}).t0str);
       % fprintf(al,'STOP_TIME  = %s\n',tabindex{tabi1,4});
%        fprintf(al,'SPACECRAFT_CLOCK_START_COUNT  = %s\n',index(tabindex{tabi0,3}).sct0str(5:end-1));
 %       fprintf(al,'SPACECRAFT_CLOCK_STOP_COUNT  = %16.6f\n',tabindex{tabi1,5});
        fprintf(al,'OBJECT = TABLE\n');
        fprintf(al,'INTERCHANGE_FORMAT = ASCII\n');
        fprintf(al,'ROWS = %d\n',an_tabindex{i,4});
        fprintf(al,'COLUMNS = %d\n',an_tabindex{i,5});
        
        
        
        %     tempfp{1,2}{28,1} = index(tabindex{tabi0,3}).t0str; %UTC start time
        %     tempfp{1,2}{29,1} = tabindex{tabi1,4};             % UTC stop time
        %     tmpsct0 = index(tabindex{tabi0,3}).sct0str(5:end-1);
        %     tempfp{1,2}{30,1} = tmpsct0;                    %% sc start time
        %     tempfp{1,2}{31,1} = sprintf('%16.6f',tabindex{tabi1,5}); %% sc stop time
        
        if strcmp(an_tabindex{i,7},'downsample')
            
            mode = tname(end-6:end-4);
            Pnum = tname(end-5);
            %  fprintf(awID,'%s, %16.6f, %14.7e, %14.7e, %14.7e, %14.7e\n',foutarr{1,1}{j,1},foutarr{1,2}(j),foutarr{1,3}(j),foutarr{1,4}(j),foutarr{1,5}(j),foutarr{1,6}(j));
            %      23, 16+1, 14+1, 14+1, 14+1, 14+1
            %      = 2*5+23+17+15*4 = 110
            
            fprintf(al,'ROW_BYTES = 110\n');   %%row_bytes here!!!
            
            fprintf(al,'DESCRIPTION = "%s SECONDS DOWNSAMPLED MEASUREMENT"\n',lname(end-10:end-9));


        
%%Varför finns det två "DESCRIPTION" i LBL filerna?
            
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = TIME_UTC\n');
            fprintf(al,'DATA_TYPE = TIME\n');
            fprintf(al,'START_BYTE = 1\n');
            fprintf(al,'BYTES = 23\n');
            fprintf(al,'UNIT = SECONDS\n');
            fprintf(al,'DESCRIPTION = "START TIME OF MACRO BLOCK YYYY-MM-DD HH:MM:SS.FFF"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = OBT_TIME\n');
            fprintf(al,'START_BYTE = 26\n');
            fprintf(al,'BYTES = 16\n'); %
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'UNIT = SECONDS\n');
            fprintf(al,'DESCRIPTION = "SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
       
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_CURRENT\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 45\n');
            fprintf(al,'BYTES = 13\n');
            fprintf(al,'UNIT = AMPERE\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "AVERAGED CURRENT"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
         
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_CURRENT_STDDEV\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 61\n');
            fprintf(al,'BYTES = 13\n');
            fprintf(al,'UNIT = AMPERE\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "CURRENT STANDARD DEVIATION"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
          
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_VOLT\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 77\n');
            fprintf(al,'BYTES = 13\n');
            fprintf(al,'UNIT = VOLT\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "AVERAGED MEASURED VOLTAGE"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_VOLT_STDDEV\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 93\n');
            fprintf(al,'BYTES = 13\n');
            fprintf(al,'UNIT = VOLT\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "VOLTAGE STANDARD DEVIATION"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'END_OBJECT  = TABLE\n');
            fprintf(al,'END');
            fclose(al);
            
        end
        
    end
end

