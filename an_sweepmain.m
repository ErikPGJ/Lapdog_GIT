%analyses sweeps, utilising modded version of Anders an_swp code, and other
%methods
function []= an_sweepmain(an_ind,tabindex,targetfullname)

global an_tabindex;
global target;
global diag_info
global CO IN     % Physical &instrumental constants

dynampath = strrep(mfilename('fullpath'),'/an_sweepmain','');
kernelFile = strcat(dynampath,'/metakernel_rosetta.txt');
paths();

cspice_furnsh(kernelFile);


k=1; %needed for error output

try
    
    for i=1:length(an_ind)
        
        
        
        
        % get file, read variables etcc
        split = 0;
        
        rfile =tabindex{an_ind(i),1};
        rfolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');
        mode=rfile(end-6:end-4);
        diagmacro=rfile(end-10:end-8);
        probe = rfile(end-5);
        diag_info{1} = strcat(diagmacro,'P',probe);

%        diag_info{1} = strcat('P',probe,'M',diagmacro);
        diag_info{2} = rfile; %let's also remember the full name
        arID = fopen(tabindex{an_ind(i),1},'r');
        
        if arID < 0
            fprintf(1,'Error, cannot open file %s', tabindex{an_ind(i),1});
            break
        end % if I/O error
        
        scantemp = textscan(arID,'%s','delimiter',',','CollectOutput', true);
        
        fclose(arID);
        
        rfile(end-6)='B';
        arID = fopen(rfile,'r');
        scantemp2=textscan(arID,'%*f%f','delimiter',',');
        
        
        % scantemp=textscan(arID,'%s%f%f%f%d','delimiter',',');
        fclose(arID);
        
        steps=    length(scantemp2{1,1})+5; %current + 4 timestamps + 1 QF
        
        size=    numel(scantemp{1,1});
        
        if mod(size,steps) ~=0
            fprintf(1,'error, bad sweepfile at \n %s \n, aborting %s mode analysis\n',rfile,mode);
            return
        end
        
        
        A= reshape(scantemp{1,1},steps,size/steps);
        Iarr= str2double(A(6:end,1:end));
        timing={A{1,1},A{2,end},A{3,1},A{4,end}};
        Qfarr =str2double(A(5,:));
        
        Vb=scantemp2{1,1};
        
        Tarr= A(1:4,1:end);       
        
        %special case where V increases e.g. +15to -15 to +15, or -15 to +15 to -15V
        potdiff=diff(Vb);    
        
        upd =max(0,sign(potdiff)); %dir is an int either 0 or 1...
        
        if potdiff(1) > 0 && Vb(end)~=max(Vb) % potbias looks like a V
            
            
            %split data
            mind=find(Vb==max(Vb));
            Vb2=Vb(mind:end);
            Iarr2=Iarr(mind:end,:);
            
            Vb=Vb(1:mind);
            Iarr= Iarr(1:mind,:);
            
            split = 1;
            
            upd = [ 0 1]; %...or it's an array of size two
            %downup
            
            
            
        elseif potdiff(1) <0 && Vb(end)~=min(Vb)
            %%potbias looks like upside-down V
            
            %split data
            mind=find(Vb==min(Vb));
            Vb2=Vb(mind:end);
            Iarr2=Iarr(mind:end,:);
            
            Vb=Vb(1:mind);
            Iarr= Iarr(1:mind,:);
            split = 1;
            
            upd = [ 1 0];
            %updown
            
            
            
            
        end
        
        %'preloaded' is a dummy entry, just so orbit realises spice kernels
        %are already loaded
        [junk,junk,SAA]=orbit('Rosetta',Tarr(1:2,:),target,'ECLIPJ2000','preloaded');
        clear junk
        
        if strcmp(mode(2),'1'); %probe 1???
            %current (Elias) SAA = z axis, Anders = x axis.
            % *Anders values* (converted to the present solar aspect angle definition
            % by ADDING 90 degrees) :
            Phi11 = 131;
            Phi12 = 181;
            
            illuminati = ((SAA < Phi11) | (SAA > Phi12));
            
            
        else %we will hopefully never have sweeps with probe number "3"
            
            %%%
            % *Anders values* (+90 degrees)
            Phi21 = 18;
            Phi22 = 82;
            Phi23 = 107;
            %illuminati = ((SAA < Phi21) | (SAA > Phi22));
            
            illuminati = ((SAA < Phi21) | (SAA > Phi22)) - 0.6*((SAA > Phi22) & (SAA < Phi23));
            % illuminati = illuminati - 0.6*((SAA > Phi22) & (SAA < Phi23));
        end
        
        
        
        len = length(Iarr(1,:));
        %  cspice_str2et(
        
        
        %% initialise output struct
        
        %Anders analysed parameters
        AP(len).ts       = [];
        AP(len).vx       = [];
        AP(len).Tph      = [];
        AP(len).Iph0     = [];
        AP(len).vs       = [];
        AP(len).lastneg  = [];
        AP(len).firstpos = [];
        AP(len).poli1    = [];
        AP(len).poli2    = [];
        AP(len).pole1    = [];
        AP(len).pole2    = [];
        AP(len).probe    = [];
        AP(len).vbinf    = [];
        AP(len).diinf    = [];
        AP(len).d2iinf   = [];
     
        %EP = extra parameters, not from functions
        
        EP(len).tstamp   = [];
        EP(len).SAA      = [];
        EP(len).qf       = [];
        EP(len).Tarr     = {};
        EP(len).lum      = [];
        EP(len).split    = [];        
        
        EP(len).ni_1comp = [];
        EP(len).ni_2comp = [];
        EP(len).asm_ni_1comp = [];
        EP(len).asm_ni_2comp = [];

      %  EP(len).ni_thermal = [];%1e-6*DP(k).ion_slope*assmpt.ionM*CO.mp*assmpt.vram/(IN.probe_cA*2*CO.e*CO.e);
     %   EP(len).ni_SW = [];%1e-6*DP(k).ion_y_intersect/ IN.probe_cA * assmpt.ionZ*CO.e*assmpt.v_SW;
        EP(len).ne_5eV = [];%1e-6*DP(k).e_slope
        %need to make this as a function of Vsc...
        % EP(len).i_v = [];%sqrt(2*assmpt.ionZ*CO.e*DP(k)DP(k).ion_y_intersect/(DP(k).ion_slope*assmpt.ionM*CO.mp);

        
        EP(len).asm_ne_5eV = [];%1e-6*DP(k).e_slope
        EP(len).dir = [];
        
        
        

        %dervied parameters from sweep    
        DP(len).Iph0                = [];
        DP(len).Tph                 = [];
        DP(len).Vsi                 = [];
        DP(len).Te                  = [];
        DP(len).ne                  = [];
        
        DP(len).Vsg                 = [];
        DP(len).Vph_knee            = [];        

        
        DP(len).ion_Vb_slope        = [];
        DP(len).ion_Vb_intersect    = [];
        DP(len).ion_slope           = [];
        DP(len).ion_intersect       = [];
        
        DP(len).e_Vb_slope          = [];
        DP(len).e_Vb_intersect      = [];       
        DP(len).e_slope             = [];
        DP(len).e_intersect         = [];
        
        DP(len).Tphc                = [];
        DP(len).nphc                = [];
        DP(len).phc_slope           = [];
        DP(len).phc_intersect       = [];
        
        DP(len).Te_exp              = [];
        DP(len).Ie0_exp             = [];
       
        DP(len).Quality  = [];

        
        DP_assmpt= DP;
        
        %% initial estimate
        
        
        %lets take the first, up to 50.  
	%note: do this for every 50th sweep?
    
    
    assmpt =[];
    
    assmpt.Vknee = 0; %dummy
    assmpt.Tph = 2; %eV
    assmpt.Iph0 = -8.55e-09; %Amp
    assmpt.vram = 7000; %m/s
    assmpt.ionZ = +1; % ion charge
    assmpt.ionM = 19; % proton mass
    assmpt.v_SW = 5E5; %500 km/s
        
    %assmpt.probearea =0.25E-3;
    

    
            %Iion0 = ?Aram qion nion vd,
    
    
    
    %% try whole batch of sweep analysis at once, why not?
    % 50 sweeps would correspond to ~ 30 minutes of sweeps

    if len > 1
        
        lmax=min(len,50); %lmax is whichever is smallest, len or 50.
        
        lind=logical(floor(mean(reshape(illuminati,2,len),1)));% logical index of all sunlit sweeps
        dind=~logical((mean(reshape(illuminati,2,len),1))); %logical index of all fully shadowed sweeps
        
        
        if unique(lind(1:lmax)) % if we have sunlit sweeps, do this
            I_50 = mean(Iarr(:,lind),2);   %average each potential step current
            [Vknee,sigma]=an_Vplasma(Vb,I_50); %get Vph_knee estimate from that.
            
            assmpt.Vknee =Vknee;
            
            init_1 = an_LP_Sweep_with_assmpt(Vb, I_50,assmpt,1);  %get initial estimate of all variables in that sweep.
        end
        
        if (unique(~(lind(1:lmax)))) % if we also) have non-sunlit sweeps?
            
            I_50 = mean(Iarr(:,~lind),2);
            [Vknee,sigma]=an_Vplasma(Vb,I_50); %get Vsg estimate from that.
            assmpt.Vknee = Vknee;
            init_2 = an_LP_Sweep_with_assmpt(Vb, I_50,assmpt,0);  %get initial estimate of all variables in that sweep.
        end
        % non-sunlit sweep V_SC should have priority!!
        


        if unique(lind+dind)==0 %if everything is in partial shade
            
            I_50 = mean(Iarr(:,1:lmax),2); %all
            [Vknee,sigma]=an_Vplasma(Vb,I_50); %get Vph_knee estimate from that.
             
            assmpt.Vknee =Vknee;
            
            init_1 = an_LP_Sweep_with_assmpt(Vb, I_50,assmpt,0.4);  %get initial estimate of all variables in that sweep.
            
            
        end
        
        
    end
    
        
        % analyse!
        for k=1:len
            

            
            %  a= cspice_str2et(timing{1,k});
            m = k;
            
            %% quality factor check
            qf= Qfarr(k);
            
            if (abs(SAA(1,2*k-1)-SAA(1,2*k)) >0.05) %rotation of more than 0.05 degrees  %arbitrary chosen value... seems decent
                qf = qf+20; %rotation
            end
            
            EP(k).SAA = mean(SAA(1,2*k-1:2*k));
            EP(k).lum = mean(illuminati(1,2*k-1:2*k));
            
            EP(k).split = 0;
            EP(k).Tarr = {Tarr{:,k}};
            
            %       fout{m,5}={Tarr{:,k}};
            EP(k).tstamp = Tarr{3,k};
            EP(k).qf = qf;
            EP(k).dir = upd(1);
            
            
            %Anders LP sweep analysis
            AP(k)=  an_swp(Vb,Iarr(:,k),cspice_str2et(Tarr{1,k}),mode(2),EP(k).lum);

                        
            if k>1
                Vguess=DP(k-1).Vph_knee;
            else
                Vguess=AP(k).vs;
            end


            DP(k)= an_LP_Sweep(Vb, Iarr(:,k),Vguess,EP(k).lum);
            DP_assmpt(k) = an_LP_Sweep_with_assmpt(Vb,Iarr(:,k),assmpt,EP(k).lum);

            %need to make this as a function of Vsc...
%            EP(k).i_v = sqrt(2*assmpt.ionZ*CO.e*DP(k)DP(k).ion_y_intersect/(DP(k).ion_slope*assmpt.ionM*CO.mp);
            
           
%            EP(k).ni_ram = 1e-6*DP(k).ion_y_intersect/ IN.probe_cA * assmpt.ionZ*CO.e*assmpt.vram; %(CO.probearea*assmpt.qion*assmpt.vram);
            %EP(k).ni_SW = 1e-6*DP(k).ion_y_intersect/ IN.probe_cA * assmpt.ionZ*CO.e*assmpt.v_SW;
            
            
            EP(k).ni_1comp = abs(1e-6 * DP(k).ion_slope(1)*assmpt.ionM*CO.mp*assmpt.vram/(2*IN.probe_cA*CO.e^2));
            EP(k).ni_2comp = (1e-6/(IN.probe_cA*CO.e))*sqrt(abs(CO.mp*(DP(k).ion_intersect(1)-DP(k).Iph0)*DP(k).ion_slope(1)/(2*CO.e)));
                                                     
            EP(k).asm_ni_1comp = abs(1e-6 * DP_assmpt(k).ion_slope(1)*assmpt.ionM*CO.mp*assmpt.vram/(2*IN.probe_cA*CO.e^2));
            EP(k).asm_ni_2comp = (1e-6/(IN.probe_cA*CO.e))*sqrt(abs(CO.mp*(DP_assmpt(k).ion_intersect(1)-DP_assmpt(k).Iph0)*DP_assmpt(k).ion_slope(1)/(2*CO.e)));
                   
            %%estimate
            Te_guess = 5;%eV
            EP(k).ne_5eV = abs(1e-6*DP(k).e_intersect(1)/(IN.probe_A*-CO.e*sqrt(CO.e*Te_guess/(2*pi*CO.me))));
            EP(k).asm_ne_5eV = abs(1e-6*DP_assmpt(k).e_intersect(1)/(IN.probe_A*-CO.e*sqrt(CO.e*Te_guess/(2*pi*CO.me))));
     

                    

                        
        end%for
        
        
        
        if (split~=0)
            
            
            for k=1:length(Iarr2(1,:))
                m=k+len;          %add to end of output array (fout{})
                %note Vb =! Vb2, Iarr =! Iarr2, etc.
                %% quality factor check
                qf= Qfarr(k);
                
                if (abs(SAA(1,2*k-1)-SAA(1,2*k)) >0.01) %rotation of more than 0.01 degrees
                    qf = qf+20; %rotation
                end
                
                %               fout{m,1} =an_swp(Vb2,Iarr2(:,k),cspice_str2et(Tarr{1,k}),mode(2),illuminati);
                %                fout{m,2} = mean(SAA(1,2*k-1:2*k)); %every pair...
                %                fout{m,3} = mean(illuminati(1,2*k-1:2*k));
                
                EP(m).SAA = mean(SAA(1,2*k-1:2*k));
                EP(m).lum = mean(illuminati(1,2*k-1:2*k));
                EP(m).Tarr = {Tarr{:,k}};
                EP(m).tstamp = Tarr{4,k};
                EP(m).qf = qf;
                EP(m).split= split; % 1 for V form, -1 for upsidedownV
                EP(m).dir = upd(2); 

                AP(m)     =  an_swp(Vb,Iarr(:,k),cspice_str2et(Tarr{1,k}),mode(2),EP(m).lum);
                %          fout{m,1} = an_swp(Vb,Iarr(:,k),cspice_str2et(Tarr{1,k}),mode(2),illuminati(k));
                %                fout{m,2} = mean(SAA(1,2*k-1:2*k));

                
                if k>1
                    Vguess=DP(m-1).Vph_knee;
                else
                    Vguess=AP(m).vs; %use last calculation as a first guess
                end
                
                DP(m) = an_LP_Sweep(Vb2,Iarr2(:,k),Vguess,EP(m).lum);
                
                DP_assmpt(m) = an_LP_Sweep_with_assmpt(Vb2,Iarr2(:,k),assmpt,EP(m).lum);
                
                %need to make this as a function of Vsc...
                %            EP(k).i_v = sqrt(2*assmpt.ionZ*CO.e*DP(k)DP(k).ion_y_intersect/(DP(k).ion_slope*assmpt.ionM*CO.mp);
 
       
                EP(m).ni_1comp = abs(1e-6 * DP(k).ion_slope(1)*assmpt.ionM*CO.mp*assmpt.vram/(2*IN.probe_cA*CO.e^2));
                EP(m).ni_2comp = (1e-6/(IN.probe_cA*CO.e))*sqrt(abs(assmpt.ionM*CO.mp*(DP(k).ion_intersect(1)-DP(k).Iph0)*DP(k).ion_slope(1)/(2*CO.e)));
 
                EP(m).asm_ni_1comp = abs(1e-6 * DP_assmpt(m).ion_slope(1)*assmpt.ionM*CO.mp*assmpt.vram/(2*IN.probe_cA*CO.e^2));
                EP(m).asm_ni_2comp = (1e-6/(IN.probe_cA*CO.e))*sqrt(abs(assmpt.ionM*CO.mp*(DP_assmpt(m).ion_intersect(1)-DP_assmpt(m).Iph0)*DP_assmpt(m).ion_slope(1)/(2*CO.e)));
                

                Te_guess = 5;%eV
                EP(m).ne_5eV = abs(1e-6*DP(m).e_intersect(1)/(IN.probe_A*-CO.e*sqrt(CO.e*Te_guess/(2*pi*CO.me))));
                EP(m).asm_ne_5eV = abs(1e-6*DP_assmpt(m).e_intersect(1)/(IN.probe_A*-CO.e*sqrt(CO.e*Te_guess/(2*pi*CO.me))));

                
                
            %
                
                
            end%for
        end%if split
        
    %    fout = sortrows(fout,6);
        %  [foutarr,~] = sortrows{foutarr,6,'ascend'};

        
        [junk,ind] = sort({EP.tstamp});
        
  %      [junk,ind] = sort({EP.tstamp});
        klen=length(ind);

        AP=AP(ind);
        DP=DP(ind);
        EP=EP(ind);
        wfile= rfile;
        wfile(end-6)='A';
        awID= fopen(wfile,'w');
        r2 = 0;



                %IF THIS HEADER IS REMOVED (WHICH IT SHOULD BE BEFORE ESA
                %DELIVERY) NOTIFY TONY ALLEN!


            fprintf(awID,strcat('START_TIME(UTC), STOP_TIME(UTC), Qualityfactor, SAA, Illumination, direction',...
            ', old.Vsi, old.Vx, Vsg, sigma_Vsg,  old.Tph, old.Iph0, Vb_lastnegcurrent, Vb_firstposcurrent',...
            ', Vbinfl, dIinfl, d2Iinfl',...
            ', Iph0, Tph, Vsi, Vph_knee, Te, ne',...
            ', ion_slope, sigma_ion_slope, ion_intersect, sigma_ion_intersect, e_slope, sigma_e_slope, e_intersect, sigma_e_intersect',...
            ', ion_Vb_slope, sigma_ion_Vb_slope, ion_Vb_intersect, sigma_ion_Vb_intersect, e_Vb_slope, sigma_e_Vb_slope, e_Vb_intersect, sigma_e_Vb_intersect',...
            ', Tphc, nphc, phc_slope, sigma_phc_slope, phc_intersect, sigma_phc_intersect',...
            ', ne_5eV, ni_1comp, ni_2comp, Te_exp, sigma_Te_exp',...
            ', asm_Vsg, asm_sigma_Vsg',...
            ', asm_Iph0, asm_Tph, asm_Vsi, asm_Vph_knee, asm_Te, asm_ne',...
            ', asm_ion_slope, asm_sigma_ion_slope, asm_ion_intersect, asm_sigma_ion_intersect, asm_e_slope, asm_sigma_e_slope, asm_e_intersect, asm_sigma_e_intersect',...
            ', asm_ion_Vb_slope, asm_sigma_ion_Vb_slope, asm_ion_Vb_intersect, asm_sigma_ion_Vb_intersect, asm_e_Vb_slope, sigma_asm_e_Vb_slope, asm_e_Vb_intersect, asm_sigma_e_Vb_intersect',...
            ', asm_Tphc, asm_nphc, asm_phc_slope, asm_sigma_phc_slope, asm_phc_intersect, asm_sigma_phc_intersect',...
            ', asm_ne_5eV, asm_ni_1comp, asm_ni_2comp, asm_Te_exp, asm_sigma_Te_exp',...       
            '\n'));



        
        % fpformat = '%s, %s, %03i, %07.4f, %03.2f, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e  %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e\n';
        for k=1:klen
            % print variables to file. seperated into substrings.
            
                
            str1  = sprintf('%s, %s, %03i, %07.3f, %03.2f, %1i,',EP(k).Tarr{1,1},EP(k).Tarr{1,2},EP(k).qf,EP(k).SAA,EP(k).lum,EP(k).dir);
            str2  = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,',AP(k).vs,AP(k).vx,DP(k).Vsg);
            str3  = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,', AP(k).Tph,AP(k).Iph0,AP(k).lastneg,AP(k).firstpos);
            str4  = sprintf(' %14.7e, %14.7e, %14.7e,',AP(k).vbinf,AP(k).diinf,AP(k).d2iinf);                 
            str5  = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP(k).Iph0,DP(k).Tph,DP(k).Vsi,DP(k).Vph_knee,DP(k).Te,DP(k).ne);           
            str6  = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP(k).ion_slope,DP(k).ion_intersect,DP(k).e_slope,DP(k).e_intersect);
            str7  = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP(k).ion_Vb_slope,DP(k).ion_Vb_intersect,DP(k).e_Vb_slope,DP(k).e_Vb_intersect);  
            str8  = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP(k).Tphc,DP(k).nphc,DP(k).phc_slope,DP(k).phc_intersect);                                                                                                      %NB DP(k).Te_exp is vector size 2, so two ouputs.           
            str9  = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',EP(k).ne_5eV,EP(k).ni_1comp,EP(k).ni_2comp,DP(k).Te_exp);
            str10 = sprintf(' %14.7e, %14.7e,',DP_assmpt(k).Vsg);            
            str11 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP_assmpt(k).Iph0,DP_assmpt(k).Tph,DP_assmpt(k).Vsi,DP_assmpt(k).Vph_knee,DP_assmpt(k).Te,DP_assmpt(k).ne);        
            str12 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP_assmpt(k).ion_slope,DP_assmpt(k).ion_intersect,DP_assmpt(k).e_slope,DP_assmpt(k).e_intersect);            
            str13 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP_assmpt(k).ion_Vb_slope,DP_assmpt(k).ion_Vb_intersect,DP_assmpt(k).e_Vb_slope,DP_assmpt(k).e_Vb_intersect);           
            str14 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP_assmpt(k).Tphc,DP_assmpt(k).nphc,DP_assmpt(k).phc_slope,DP_assmpt(k).phc_intersect);
            str15 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e',EP(k).asm_ne_5eV,EP(k).asm_ni_1comp,EP(k).asm_ni_2comp,DP_assmpt(k).Te_exp);

            
            strtot= strcat(str1,str2,str3,str4,str5,str6,str7,str8,str9,str10,str11,str12,str13,str14,str15);
            strtot=strrep(strtot,'Inf','   ');
            %strtot=strrep(strtot,'NaN','   ');
            
  
            %If you need to change NaN to something (e.g. N/A, as accepted by Rosetta Archiving Guidelines) change it here!
            
            
            row_bytes =fprintf(awID,'%s\n',strtot);
            

            
            
        end
        fclose(awID);
        
        an_tabindex{end+1,1} = wfile;%start new line of an_tabindex, and record file name
        an_tabindex{end,2} = strrep(wfile,rfolder,''); %shortfilename
        an_tabindex{end,3} = tabindex{an_ind(i),3}; %first calib data file index
        %an_tabindex{end,3} = an_ind(1); %first calib data file index of first derived file in this set
        an_tabindex{end,4} = klen; %number of rows
        an_tabindex{end,5} = 85; %number of columns
        an_tabindex{end,6} = an_ind(i);
        an_tabindex{end,7} = 'sweep'; %type
        an_tabindex{end,8} = timing;
        an_tabindex{end,9} = row_bytes;
        
        %clear output structs before looping again
        clear AP DP EP
    end
    
    cspice_unload(kernelFile);  %unload kernels when exiting function
%     
catch err
    
    fprintf(1,'Error at loop step %i, file %s',i,tabindex{an_ind(i),1});
    if ~isempty(k)
        fprintf(1,'\n Error at loop step k=%i,',k);
    end
    err.identifier
    err.message
    len = length(err.stack);
    if (~isempty(len))
        for i=1:len
            fprintf(1,'%s, %i,',err.stack(i).name,err.stack(i).line);
        end
    end
    cspice_unload(kernelFile);
        
    
end


end


%             
%             format4 =' %14.7e, %14.7e, %14.7e, %14.7e,';
%             format8 =strcat(format4,format4);
%             format2 =' %14.7e, %14.7e,';
% 
%             str1  = sprintf('%s, %s, %03i, %07.3f, %03.2f, %1i,',EP(k).Tarr{1,1},EP(k).Tarr{1,2},EP(k).qf,EP(k).SAA,EP(k).lum,EP(k).dir);
%             str2  = sprintf(format4,AP(k).vs,AP(k).vx,AP(k).Tph,AP(k).Iph0);
%             str3  = sprintf(format4,AP(k).lastneg,AP(k).firstpos,AP(k).vbinf,AP(k).diinf,);
%             str4  = sprintf(' %14.7e,'AP(k).d2iinf);
%             
%             
%             str10 =  sprintf(format4,DP(k).,DP(k).Vsg_sigma,DP(k).Iph0,DP(k).Tph);
%             str5  =  sprintf(format4,DP(k).Vsi,DP(k).Vph_knee,DP(k).Te,DP(k).ne);
%             str6  = sprintf(format8,DP(k).ion_slope,DP(k).ion_intersect,DP(k).e_slope,DP(k).e_intersect);
%             str7  = sprintf(format8,DP(k).ion_Vb_slope,DP(k).ion_Vb_intersect,DP(k).e_Vb_slope,DP(k).e_Vb_intersect);
%             str8  = sprintf(format4,DP(k).Tphc,DP(k).nphc,DP(k).phc_slope,DP(k).phc_intersect);
%             str9  = sprintf(format4 %14.7e,',EP(k).ne_5eV,EP(k).ni_1comp,EP(k).ni_2comp,DP(k).Te_exp);
%             str10 = sprintf(' %14.7e, %14.7e,',DP_assmpt(k).Vsg,DP_assmpt(k).Vsg_sigma);
%             str11 = sprintf(format4 %14.7e,',DP_assmpt(k).Iph0,DP_assmpt(k).Tph,DP_assmpt(k).Vsi,DP_assmpt(k).Vph_knee,DP_assmpt(k).Te,DP_assmpt(k).ne);
%             str12 = sprintf(format8,DP_assmpt(k).ion_slope,DP_assmpt(k).ion_intersect,DP_assmpt(k).e_slope,DP_assmpt(k).e_intersect);
%             str13 = sprintf(format8,DP_assmpt(k).ion_Vb_slope,DP_assmpt(k).ion_Vb_intersect,DP_assmpt(k).e_Vb_slope,DP_assmpt(k).e_Vb_intersect);
%             str14 = sprintf(format4,DP_assmpt(k).Tphc,DP_assmpt(k).nphc,DP_assmpt(k).phc_slope,DP_assmpt(k).phc_intersect);
%             str15 = sprintf( format4 %14.7e',EP(k).asm_ne_5eV,EP(k).asm_ni_1comp,EP(k).asm_ni_2comp,DP_assmpt(k).Te_exp);

            
