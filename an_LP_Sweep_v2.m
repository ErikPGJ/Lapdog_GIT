%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Name: an_LP_Sweep_V2.m
% Author: Fredrik Johansson, developed from original script by Claes Weyde
% % Thomas Nilsson (IRFU)
%
% Description:
%
%  	This is the main function body. It is the function LP_AnalyseSweep from which all other functions are
%	called. It returns the determined plasma parameters; Vsc, ne, Te.
%
%   1. The sweep is sorted upwards and smoothed
%
%   2. Find the spacecraft potential (Vsc) and Vph_knee.
%   if sunlit: Vph_knee = Vplasma is the plasma at the probe
%   potential from finding the knee of the photoelectron current
%
%   3. evaluate if the sweep is truly sunlit or not, in the case of
%   ambiguous illumination input.
%
%
%   4. Fitting an ion current to the part of the sweep below the knee (and
%   below Vsc). And then subtracting the current contribution from the ions
%   from the sweep.
%
%   5. Fitting an electron current by a linear fit (LP_electron_curr.m)
%   above Vsc or an exponential fit (LP_expfit_Te.m) below Vknee. removing
%   the linear fit electron current contribution from the sweep.
%
%   6. Fitting a photoelectron current (if sunlit) to the remainding
%   current.
%
%   7. redo step 4, but with a removed static photoelectron current (if
%   sunlit)
%   8. repeat step 5 with results from step 7
%
%   9. Output variables.
%
%
% Input:
%     V             bias potential
%     I             sweep current
%     Vguess        spacecraft potential guess from previous analysis
%     illuminated   if the probe is sunlit or not (from SPICE Kernel SAA
%     evaluation)
%
% Output:
%	  DP        Physical paramater information structure, dynamic solution
%     DP_asm    "    " as above with static photoelectron current solution
% Notes:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [DP,DP_asm] = an_LP_Sweep_v2(V, I,Vguess,illuminated)

global CO IN     % Physical &instrumental constants
global assmpt; %global assumptions
global an_debug diag_info VSC_TO_VPLASMA VSC_TO_VKNEE;
%VSC_TO_VPLASMA=0.64; %from SPIS simulation experiments
%VSC_TO_VKNEE = 0.36;
VSC_TO_VPLASMA=1;
VSC_TO_VKNEE = 1;

%warning off; % For unnecessary warnings (often when taking log of zero, these values are not used anyways)
Q    = [0 0 0 0];   % Quality vector

% Initialize DP to ensure a return value:
DP = [];

DP.Iph0             = NaN;
DP.Tph              = NaN;
DP.Vsi              = NaN;
DP.Te               = nan(1,2);
DP.ne               = nan(1,2);

DP.Vsg              = nan(1,2);
DP.Vph_knee         = nan(1,2);
DP.Vbar             = nan(1,2);

DP.Vsg_lowAc              = nan(1,2);
DP.Vph_knee_lowAc         = nan(1,2);
DP.Vbar_lowAc             = nan(1,2);



DP.ion_Vb_slope     = nan(1,2);
DP.ion_Vb_intersect = nan(1,2);
DP.ion_slope        = nan(1,2);
DP.ion_intersect    = nan(1,2);
DP.ion_Up_slope     = nan(1,2);
DP.ion_Up_intersect = nan(1,2);

DP.ni_1comp         = NaN;
DP.ni_2comp         = NaN;
DP.v_ion            = NaN;
DP.ni_aion          = NaN;
DP.Vsc_aion         = NaN;
DP.v_aion           = NaN;


DP.e_Vb_slope       = nan(1,2);
DP.e_Vb_intersect   = nan(1,2);
DP.e_slope          = nan(1,2);
DP.e_intersect      = nan(1,2);

DP.Tphc             = NaN;
DP.nphc             = NaN;
DP.phc_slope        = nan(1,2);
DP.phc_intersect    = nan(1,2);

DP.Te_exp           = nan(1,2);
DP.Ie0_exp          = nan(1,2);
DP.ne_exp           = nan(1,2);
DP.Te_exp_belowVknee   = nan(1,2);
DP.Ie0_exp_belowVknee  = nan(1,2);
DP.ne_exp_belowVknee   = nan(1,2);

DP.Quality          = sum(Q);

DP.Rsq              = [];
DP.Rsq.linear       = NaN;
DP.Rsq.exp          = NaN;

Iph= 0;


DP_asm = DP;        %initialise DP_asm
DP_asm.Iph0             = assmpt.Iph0;
DP_asm.Tph              = assmpt.Tph;



try %try the dynamic solution first, then the static.
    
    
    %PREPROCESSING
    %---------------------------------------------------
    %---------------------------------------------------
    
    % Sort the data
    [V,I] = LP_Sort_Sweep(V',I');
    
    
    %FILTERING
    %---------------------------------------------------
    % I've given up on analysing unfiltered data, it's just too nosiy.
    %Let's do a classic LP moving average, that doesn't move the knee
    % Is = LP_MA(I); %Terrible for knees in end-4:end
    %dv = S.step_height*IN.VpTM_DAC; % Step height in volt.
    dv = V(2)-V(1);
    Is = sweepFilterChooser_test(I,dv);
    
    % Find Photoelectron & electron knees!
    %---------------------------------------------------
    
    % First determine the spacecraft potential
    % The spacecraft potential is denoted Vsc
    %    [Vknee, Vknee_sigma] = an_Vplasma(V,Is);
    %    [Vsc, Vsc_sigma] = an_Vsc(V,Is);
    
    twinpeaks_low   = an_Vplasma_v2(V,Is);
    
    if illuminated == 0   %an_Vplasma_highAc doesn't work if shadowed
        twinpeaks = twinpeaks_low;   
    else
        twinpeaks_high = an_Vplasma_highAc(V,Is);
        twinpeaks = twinpeaks_high; %use high activity analysis for the rest, it's better
    end
    
   
    DP.Vsg_lowAc              = twinpeaks_low.Vsc;
    DP.Vph_knee_lowAc         = twinpeaks_low.Vph_knee;
    DP.Vbar_lowAc             = twinpeaks_low.Vbar;
    
    Vknee       = twinpeaks.Vph_knee(1);
    Vknee_sigma = twinpeaks.Vph_knee(2);
    %    [Vsc, Vsc_sigma] =twinpeaks.Vsc;
    %    Vsc = twinpeaks.Vsc(1);
    %    Vsc_sigma =twinpeaks.Vsc(2);
    
    Vsc = twinpeaks.Vbar(1);
    Vsc_sigma =twinpeaks.Vbar(2);
    
    if isnan(Vsc)
        Vsc = twinpeaks.Vsc(1);
    end
    if isnan(Vknee)
        Vknee = Vguess;
    end
    %---------------------------------------------------
    %test the partial shadow conditions!!!
    if illuminated > 0 && illuminated < 1
        Q(1)=1;
        test= find(abs(V +Vknee)<1.5,1,'first');
        if Is(test) > 0 %if current is positive, then it's not sunlit
            illuminated = 0;
        else %current is negative, so we see photoelectron knee.
            illuminated = 1;
        end
    end
    %---------------------------------------------------
    
    if(illuminated)
        if isnan(Vsc)
            Vsc= Vknee/VSC_TO_VKNEE;
            %Vsc_sigma =Vknee_sigma/VSC_TO_VKNEE;
        end
        Vplasma=(Vknee/VSC_TO_VKNEE)/VSC_TO_VPLASMA;
        
    else
        Vsc=Vknee;
        %Vsc_sigma = Vknee_sigma;
        twinpeaks.Vsc = twinpeaks.Vph_knee;
        %Vsc=Vknee; %no photoelectrons, so current only function of Vp (absolute)
        Vplasma=NaN;
    end
    %---------------------------------------------------
    
    
    
    %---------------------------------------------------
    %---------------------------------------------------
    %---DYNAMIC SOLUTION!
    %---------------------------------------------------
    %---------------------------------------------------
    % Lets find the currents!
    %---------------------------------------------------------
    
    
    
    
    
    % Next we determine the ion current, Vsc need to be included in order
    % to determine the probe potential..In addition to the ion current,
    % the coefficients from
    % the linear fit  are also returned
    % [Ii,ia,ib] = LP_Ion_curr(V,LP_MA(I),Vsc);
    
    [ion] = LP_Ion_curr(V,Is,Vsc,Vknee); % The ion current is denoted ion.I,
    
    
    if (an_debug>1)%debug plot
        
        figure(33)
        subplot(3,2,3);plot(V+Vsc,Is,'b',V+Vsc,ion.I,'g');grid on;
        title([sprintf('Ion current vs Vp, out.Q(1)=%d',ion.Q(1))])
        legend('I','I_i_o_n')
        
    end
    
    
    if illuminated %filter the Iph dominated region before exponential fit
        % find region 1 V below knee and 4V above knee
        %track positions to be filtered which is in this this region
        
        filter_ind = find(ge(V+Vplasma+1,0) &le(V+Vplasma-4,0));
        filter_max = min(filter_ind):length(V);
    else
        filter_ind = [];
        filter_max = [];
    end
    
    
    %this is all we need to get a good estimate of Te from an
    %exponential fit
    
    expfit= LP_expfit_Te(V,Is-ion.I,Vsc,filter_ind);
    DP.Te_exp           = expfit.Te; %contains both value and sigma frac.
    DP.Ie0_exp          = expfit.Ie0;
    DP.ne_exp           = expfit.ne;
    
    
    expfit_belowVknee = LP_expfit_Te(V,Is-ion.I,Vsc,filter_max);
    DP.Te_exp_belowVknee            = expfit_belowVknee.Te; %contains both value and sigma frac.
    DP.Ie0_exp_belowVknee           = expfit_belowVknee.Ie0;
    DP.ne_exp_belowVknee            = expfit_belowVknee.ne;
    
    
    
    %%% Now, removing the linearly fitted ion-current from the
    % current will leave the collected plasma electron current & photoelectron current
    
    
    if(illuminated &&~isnan(ion.b(1)))
        % if we want to determine Iph0 seperately, we need to remove the
        % ion.b component of the ion current before we accidentally remove
        % it everywhere. ion.b is otherwise a good guess for Iph0;
        ion.I = ion.I-ion.b(1);
    end
    
    
    Itemp = Is - ion.I;   %the resultant current should be electrons & photoelectrons
    
    
    if (an_debug>1) %debug plot
        figure(33);
        
        subplot(3,2,6),plot(V,Is,'b',V,Itemp,'g');grid on;
        
        title([sprintf('Vb vs I %s %s',diag_info{1},strrep(diag_info{1,2}(end-26:end-12),'_',''))])
        
        legend('I','I-Iion','Location','Northwest')
    end
    
    
    %-----------------------------------------------------------------
    %Determine the electron current (above Vsc and positive)
    [elec]=LP_Electron_curr(V,Itemp,Vsc,Vknee,illuminated);
    
    
    %if the plasma electron current fail, try the spacecraft photoelectron
    %cloud current analyser
    if isnan(elec.Te(1))
        
        [Ts,ns,elec.I,sa,sb]=LP_S_curr(V,Itemp,Vplasma,illuminated);
        DP.Tphc             = Ts;
        DP.nphc             = ns;
        DP.phc_slope        = sa;
        DP.phc_intersect    = sb;
        
        %note that Ie is now current from photo electron cloud
        
    end
    
    
    if (an_debug>1) %debug plot
        figure(33);
        subplot(3,2,1),plot(V,Is,'b',V,Itemp- elec.I,'g',V,Itemp-expfit.I,'r',V,Itemp-expfit_belowVknee.I,'black');grid on;
        title([sprintf('I, I-Ii-Ie linear, I-Ii-Ie exp %s %s',diag_info{1},strrep(diag_info{1,2}(end-26:end-12),'_',''))])
        legend('I','I-I linear','I-I exp','I-I expbelowVphknee','Location','NorthWest')
    end
    
    %the resultant current should only be photoelectron current (or zero)
    
    Itemp = Itemp - elec.I;
    
    
    %--------------
    if(illuminated) % the dynamic
        
        Iph = Itemp;
        
        
        %     iph = ip(pos) - iecoll;
        %     vbh = vb(pos);
        %
        %
        %
        %         % Use curve above vinf:
        %         pos = find(V >= Vsc);
        %
        %         % Subtract collected electrons, whose current is put to zero if
        %         % linear fit gives negative value:
        %         iph = ip(pos) - iecoll;
        %         vbh = vb(pos);
        
        % Do log fit to first 6 V:
        %     phind = find(V < (vPlasma-Vsc) + 6 & V>=(vPlasma-Vsc));
        %     [phpol,S] = polyfit(V(phind),log(abs(Iph(phind))),1);
        %     S.sigma = sqrt(diag(inv(S.R)*inv(S.R')).*S.normr.^2./S.df);
        %
        %     Tph = -1/phpol(1);
        %     Iftmp = -exp(phpol(2));
        %
        %     % Find Vsc as intersection of ion and photoemission current:
        %     % Iterative solution:
        %     vs = vPlasma-Vsc;
        %     for(i=1:10)
        %         vs = -(log(-polyval([ia(1),ion.b(1)],-vs)) - phpol(2))/phpol(1);
        %     end
        %     % Calculate Iph0:
        %     Iph0 = Iftmp * exp(vs/Tph);
        
        Vdagger = V + Vknee;
        
        %Vdagger = V + Vsc - Vplasma;
        
        phind = find(Vdagger < 6 & Vdagger>0);
        
        [phpol,S]=polyfit(Vdagger(phind),log(abs(Iph(phind))),1);
        S.sigma = sqrt(diag(inv(S.R)*inv(S.R')).*S.normr.^2./S.df);
        
        Tph = -1/phpol(1);   %Tph>> 1 -> slope very small and negative.  Tph < 0 -> slope positive (not photoelectron knee)
        Iftmp = -exp(phpol(2));
        
        %get V intersection of ion and photoelectron current:
        
        %diph = abs(  ion current(tempV)  - photelectron log current(Vdagger) )
        diph = abs(ion.a(1)*V + ion.b(1)-Iftmp*exp(-(V+Vknee)/Tph));
        %find minimum
        idx1 = find(diph==min(diph),1);
        
        
        
        % add 1E5 accuracy on min, and try it again
        tempV = V(idx1)-1:1E-5:(V(idx1)+1);
        diph = abs(ion.a(1)*tempV + ion.b(1) -Iftmp*exp(-(tempV+Vknee)/Tph));
        eps = abs(Iftmp)/1000;  %good order estimate of minimum accuracy
        idx = find(diph==min(diph) & diph < eps,1);
        
        
        
        if(isempty(idx))
            DP.Vsi = NaN;
            Q(4) = 1;
            DP.Iph0 = NaN;
            
            Iph(:)=0;
        else
            DP.Vsi = tempV(idx);
            DP.Iph0 = Iftmp * exp(-(tempV(idx)+Vknee)/Tph);
            
            
            %---------------------------- redo ion calculations to account for Iph0!!!!--------------------------------------------%
            %---- redo ion calculations to account for Iph0!!!!----%
            ion.b(1) = ion.b(1)-DP.Iph0;  % now that we know Iph0, we can calculate the actual y-intersect of the ion current.
            ion.Vpb(1) = ion.Vpb(1)-DP.Iph0;
            ion.Upb(1) = ion.Upb(1)-DP.Iph0;
            
            %ion.ni_1comp     = max((1e-6 * ion.Vpa(1) *assmpt.ionM*CO.mp*assmpt.vram/(2*IN.probe_cA*CO.e^2)),0);
            if ion.a(1) > 0
                if (ion.Vpb(1) < 0) %unphysical if intersection is above zero!
                    ion.ni_2comp    = (1e-6/(IN.probe_cA*CO.e))*sqrt((-assmpt.ionM*CO.mp*(ion.Vpb(1)) *ion.Vpa(1) /(2*CO.e)));
                    ion.v_ion       =  ion.ni_2comp     *assmpt.vram/ion.ni_1comp;
                else
                    ion.ni_2comp    = NaN;
                    ion.v_ion       = NaN;
                    
                end
                
                %Accelerated ions calculations
                
                if (ion.Upb(1) < 0) %unphysical if intersection is above zero!
                    ion.ni_aion     = (1e-6/(IN.probe_cA))*sqrt((-assmpt.ionM*CO.mp*ion.Upa(1)*ion.Upb(1)/((2*CO.e.^3))));
                else
                    ion.ni_aion     = NaN;
                end
                ion.Vsc_aion    = Vknee  +ion.Upb(1)/ion.Upa(1);
                ion.v_aion      = sqrt(-2*CO.e*(ion.Vsc_aion-Vknee)/(CO.mp*assmpt.ionM));
                
            else
                ion.ni_2comp    = NaN;
                ion.v_ion       = NaN;
                ion.ni_aion     = NaN;
                ion.Vsc_aion    = NaN;
                ion.v_aion      = NaN;
            end
            
            %----------------------------------------------------------------------------------------------------------------------%
            if Tph>0 
                Iph(:) = DP.Iph0;  %set everything to photosaturation current
                
                %    Iph(1:idx1)=DP.Iph0; %add photosaturation current
                
                %idx is the at point where Iion and Iph converges
                %Iph(idx1:end)=Iftmp*exp(-(V(idx1:end)+Vsc-Vplasma)/Tph);
                Iph(idx1+1:end)=Iftmp*exp(-Vdagger(idx1+1:end)/Tph);
                
            else %very bad 
                Iph(:)=0;
                Tph = NaN;
            end
            
            
        end
        
        DP.Tph     = Tph;
        
        
        
        %Iph0 and ion.I is both an approximation of that part of the sweep, so we
        %remove that region of the Iph current (and maybe add it later)
        %
        %
        %         Iph(1:idx1)=DP.Iph0; %add photosaturation current
        
    end
    
    
    
    %----------------------------------------------------------
    % Rsquare value calculation of fit
    
    Itot_linear=Iph+elec.I+ion.I;
    Itot_exp=Itot_linear-elec.I+expfit.I;
    Itot_exp_belowVknee = expfit_belowVknee.I+Iph+ion.I;
    
    Izero_linear = I-Itot_linear;
    Izero_exp = I - Itot_exp;
    Izero_exp_belowVknee = I - Itot_exp_belowVknee;

    
    
    Rsq_linear = 1 - nansum((Izero_linear.^2))/nansum(((I-nanmean(I)).^2));
    Rsq_exp = 1 -  nansum(Izero_exp.^2)/nansum((I-nanmean(I)).^2);
    
    Rsq_exp_belowVknee = 1 -  nansum(Izero_exp_belowVknee.^2)/nansum((I-nanmean(I)).^2);

    
    %----------------------------------------------------------
    %Output Variables
    
    %DP.Iph0     = NaN;
    %DP.Tph     = NaN;%defined elsewhere...
    
    DP.Te      = elec.Te;
    DP.ne      = elec.ne;
    DP.Vsg     = twinpeaks.Vsc;
    DP.Vph_knee = [Vplasma Vknee_sigma];
    DP.Vbar     = twinpeaks.Vbar;
    
    
    DP.ion_Vb_slope      = ion.a;
    DP.ion_Vb_intersect  = ion.b;
    DP.ion_slope      = ion.Vpa;
    DP.ion_intersect  = ion.Vpb;
    DP.ion_Up_slope     = ion.Upa;
    DP.ion_Up_intersect = ion.Upb;
    
    
    DP.ni_1comp         = ion.ni_1comp;
    DP.ni_2comp         = ion.ni_2comp;
    DP.v_ion            = ion.v_ion;
    
    DP.ni_aion          =ion.ni_aion;
    DP.Vsc_aion         =ion.Vsc_aion ;
    DP.v_aion           =ion.v_aion ;
    
    
    DP.e_Vb_slope        = elec.a;
    DP.e_Vb_intersect    = elec.b;
    DP.e_slope        = elec.Vpa;
    DP.e_intersect    = elec.Vpb;
    DP.Quality = sum(Q);
    
    DP.Rsq.linear       = Rsq_linear;
    DP.Rsq.exp          = Rsq_exp;
    
    
    if (an_debug>1) %debug plot
        figure(33);
        
        
        
        
        
        subplot(3,2,2)
        plot(V+Vsc,Izero_linear,'og',V+Vsc,Izero_exp,'or',V+Vsc,Izero_exp_belowVknee,'oblack');
        grid on;
        %  title('V vs I - ions - electrons-photoelectrons');
        title([sprintf('Vp vs I-Itot, fully auto,lum=%d, %s',illuminated,diag_info{1})])
        legend('residual(I-Itot linear)','residual(I-Itot exp)','residual(I-Itot expVknee)','Location','Northwest')
        
        
        axis([-30 30 -5E-9 5E-9])
        %axis 'auto x'
        subplot(3,2,4)
        plot(V+Vsc,Is,'b',V+Vsc,Itot_linear,'g',V+Vsc,Itot_exp,'r',V+Vsc,Itot_exp_belowVknee,'black');
        
        %        title('Vp vs I & Itot ions ');
        title([sprintf('Vp vs I, macro: %s',diag_info{1})])
        legend('I','Itot linear','Itot exp','Itot expVknee','Location','NorthWest')
        
        grid on;
        
        
        subplot(3,2,5)
        if(illuminated)
            plot(V+Vsc,I-Iph,'b',V+Vsc,(ion.I+elec.I)+ion.mean(1),'g',V+Vsc,ion.I+expfit.I+ion.mean(1),'r',V+Vsc,Iph,'black')
            
        else
            plot(V+Vsc,I-Iph,'b',V+Vsc,(ion.I+elec.I)+ion.mean(1),'g',V+Vsc,ion.I+expfit.I+ion.mean(1),'r',V+Vsc,Iph,'black')
            
        end
        
        %plot(V+Vsc,I-Iph,'b',V+Vsc,(ion.I+elec.I)+ion.mean(1),'g',V+Vsc,ion.I+expfit.I+ion.mean(1),'r',V+Vsc+Vplasma,Iph,'black')
        axis([min(V)+Vsc max(V)+Vsc min(I) max(I)])
        title([sprintf('Vp vs I, fully auto,lum=%d, %s',illuminated,diag_info{1})])
        legend('I-pe','ion+e(linear)','Ions+e(exp)','pe','Location','Northwest')
        
        
        grid on;
        
    end
    
    
    
    %end
    
    %--------------------------------------------------------------------------------------------------------------------
    %--------------------------------------------------------------------------------------------------------------------
    %--------------------------------------------------------------------------------------------------------------------
    %--------------------------------------------------------------------------------------------------------------------
    %% Let's do everything again, but let's try with an assumed photoelectron
    % current instead!
    
    asm_Itemp = Is;
    
    if illuminated
        asm_Iph = gen_ph_current(V,-Vplasma,assmpt.Iph0,assmpt.Tph,2); %model two works better for massive electron bullshit.
        asm_Itemp = asm_Itemp - asm_Iph;
        
        %[Vsc, Vsigma2] = an_Vsc(V,Itemp);
        
        
        if (an_debug>1) %debug plot
            figure(34);
            
            subplot(3,2,4),plot(V,I,'b',V,asm_Itemp,'g');grid on;
            
            title('I & I - Iph current');
            legend('I','I-Iph','Location','Northwest')
        end
        
    else
        %no need to continue here, since the dynamic would give the same results
        
        DP_asm = DP; %output same results.
        return;
    end
    
    
    
    
    % Next we determine the ion current, Vsc need to be included in order
    % to determine the probe potential. However Vsc do not need to be that
    % accurate here.In addition to the ion current, the coefficients from
    % the linear fit  are also returned and estimates of the ion density.
    [asm_ion] = LP_Ion_curr(V,asm_Itemp,Vsc,Vknee); % The ion current is denoted Ii,
    
    if (an_debug>1)  %debug plot
        figure(34);
        
        subplot(3,2,3),plot(V+Vsc,I,'b',V+Vsc,asm_ion.I,'g');grid on;
        title([sprintf('Ion current vs Vp, out.Q(1)=%d',asm_ion.Q(1))])
        legend('I','I_i_o_n')
        
    end
    
    %----------------------------------------------------------
    % Now, removing the linearly fitted ion-current from the
    % current will leave the collected plasma electron current
    
    asm_Itemp = asm_Itemp - asm_ion.I;
    
    
    if (an_debug>1)  %debug plot
        
        subplot(3,2,6),plot(V,Is,'b',V,asm_Itemp,'g');grid on;
        
        title([sprintf('Vb vs I %s %s',diag_info{1},strrep(diag_info{1,2}(end-26:end-12),'_',''))])
        
        legend('I','I-(ph+ion)','Location','NorthWest')
    end
    
    
    
    
    
    %Determine the electron current (above Vsc and positive), use a moving average
    %[Te,ne,Ie,ea,eb]=LP_Electron_curr(V,Itemp,Vsc,illuminated);
    %this time, we have already removed Iph component, so we can assume no
    %sunlight effect
    
    [asm_elec]=LP_Electron_curr(V,asm_Itemp,Vsc,Vknee,0);
    
    
    
    
    
    
    % find region 1 V below knee and 4V above knee
    %track positions to be filtered which is in this this region
%    filter_ind = find(ge(V+Vplasma+1,0) &le(V+Vplasma-4,0));
    
    %obtain exponential fit of plasma electron current.
    asm_expfit= LP_expfit_Te(V,asm_Itemp,Vsc, filter_ind);
    
    
    DP_asm.Te_exp           = asm_expfit.Te; %contains both value and sigma frac.
    DP_asm.Ie0_exp          = asm_expfit.Ie0;
    DP_asm.ne_exp           = asm_expfit.ne;
    
    
        
    
    asm_expfit_belowVknee = LP_expfit_Te(V,Is-ion.I,Vsc,filter_max);
    DP_asm.Te_exp_belowVknee            = asm_expfit_belowVknee.Te; %contains both value and sigma frac.
    DP_asm.Ie0_exp_belowVknee           = asm_expfit_belowVknee.Ie0;
    DP_asm.ne_exp_belowVknee            = asm_expfit_belowVknee.ne;
    
    
    
    
    
    %if the plasma electron current fail, try the spacecraft photoelectron
    %cloud current analyser
    
    
    
    
    
    if isnan(asm_elec.Te(1))
        
        [Ts,ns,asm_elec.I,sa,sb]=LP_S_curr(V,asm_Itemp,Vplasma,illuminated);
        
        DP_asm.Tphc             = Ts;
        DP_asm.nphc             = ns;
        DP_asm.phc_slope        = sa;
        DP_asm.phc_intersect    = sb;
        %note that Ie is now current from photo electron cloud
    end
    
    
    
    %
    if (an_debug>1)  %debug plot
        figure(34);
        subplot(3,2,1),plot(V,Is,'b',V,asm_Itemp - asm_elec.I,'g',V,asm_Itemp -asm_expfit.I,'r');grid on;
        title([sprintf('I, I-all_linear, I-all_exp %s %s',diag_info{1},strrep(diag_info{1,2}(end-26:end-12),'_',''))])
        legend('I','I-I\_linear','I-I\_exp','Location','NorthWest')
    end
    %
    % asm_Itemp = asm_Itemp - asm_elec.I; %the resultant current should only zero)
    
    
    %----------------------------------------------------------
    %get V intersection:
    
    Tph = assmpt.Tph;
    Iftmp = assmpt.Iph0;
    
    %diph = abs(  ion current(tempV)  - photelectron log current(Vdagger) )
    diph = abs(asm_ion.a(1)*V + asm_ion.b(1) -Iftmp*exp(-(V+Vsc-Vplasma)/Tph));
    %find minimum
    idx1 = find(diph==min(diph),1);
    
    % add 1E5 accuracy on min, and try it again for ?1 V.
    tempV = V(idx1)-1:1E-5:(V(idx1)+1);
    diph = abs(asm_ion.a(1)*tempV + asm_ion.b(1) -Iftmp*exp(-(tempV+Vsc-Vplasma)/Tph));
    eps = abs(Iftmp)/1000;  %good order estimate of minimum accuracy
    idx = find(diph==min(diph) & diph < eps,1);
    
    if(isempty(idx))
        DP_asm.Vsi = NaN;
    else
        DP_asm.Vsi = tempV(idx);
    end
    
    
    %----------------------------------------------------------
    % Rsquare value calculation of fit
    
    Itot_linear=asm_Iph+asm_elec.I+asm_ion.I;
    Itot_exp=Itot_linear-asm_elec.I+asm_expfit.I;
    Itot_exp_belowVknee =  Itot_linear-elec.I+asm_expfit_belowVknee.I;

    Izero_linear = I-Itot_linear;
    Izero_exp = I - Itot_exp;
    Izero_exp_belowVknee = I - Itot_exp_belowVknee;

    
    Rsq_linear = 1 - nansum((Izero_linear.^2))/nansum(((I-nanmean(I)).^2));
    Rsq_exp = 1 -  nansum(Izero_exp.^2)/nansum((I-nanmean(I)).^2);
    Rsq_exp_belowVknee = 1 -  nansum(Izero_exp_belowVknee.^2)/nansum((I-nanmean(I)).^2);

    

    
    
    
    
    %----------------------------------------------------------
    % Output variables
    
    DP_asm.Te      = asm_elec.Te;
    DP_asm.ne      = asm_elec.ne;
    DP_asm.Vsg     = twinpeaks.Vsc;
    
    DP_asm.Vph_knee = [Vplasma Vknee_sigma];
    DP_asm.Vbar     = twinpeaks.Vbar;
    
    DP_asm.ion_Vb_slope     = asm_ion.a;
    DP_asm.ion_Vb_intersect = asm_ion.b;
    DP_asm.ion_slope        = asm_ion.Vpa;
    DP_asm.ion_intersect    = asm_ion.Vpb;
    DP_asm.ion_Up_slope     = asm_ion.Upa;
    DP_asm.ion_Up_intersect = asm_ion.Upb;
    
    
    DP_asm.ni_1comp         = asm_ion.ni_1comp;
    DP_asm.ni_2comp         = asm_ion.ni_2comp;
    DP_asm.v_ion            = asm_ion.v_ion;
    
    DP_asm.ni_aion          =asm_ion.ni_aion;
    DP_asm.Vsc_aion         =asm_ion.Vsc_aion ;
    DP_asm.v_aion           =asm_ion.v_aion ;
    
    
    
    DP_asm.e_Vb_slope        = asm_elec.a;
    DP_asm.e_Vb_intersect    = asm_elec.b;
    DP_asm.e_slope           = asm_elec.Vpa;
    DP_asm.e_intersect       = asm_elec.Vpb;
    DP_asm.Quality           = sum(Q);
    
    DP_asm.Rsq.linear       = Rsq_linear;
    DP_asm.Rsq.exp          = Rsq_exp;
    
    
    
    
    
    if (an_debug>1)  %debug plot
        

        
        
        
        
        figure(34);
        subplot(3,2,2)
        plot(V+Vsc,Izero_linear,'og',V+Vsc,Izero_exp,'or',V+Vsc,Izero_exp_belowVknee,'oblack');

  %      plot(V+Vsc,Izero_linear,'og',V+Vsc,Izero_exp,'or');
        grid on;
        %  title('V vs I - ions - electrons-photoelectrons');
        title([sprintf('WITH ASSUMPTIONS lum=%d, %s',illuminated,diag_info{1})])
        legend('residual(I-Itot linear)','residual(I-Itot exp)','residual(I-Itot expVknee)','Location','Northwest')
        
        axis([-30 30 -5E-9 5E-9])
        %axis 'auto x'
        subplot(3,2,4)
         plot(V+Vsc,Is,'b',V+Vsc,Itot_linear,'g',V+Vsc,Itot_exp,'r',V+Vsc,Itot_exp_belowVknee,'black');
%        plot(V+Vsc,Is,'b',V+Vsc,Itot_linear,'g',V+Vsc,Itot_exp,'r');
        %        title('Vp vs I & Itot ions ');
        title([sprintf('Vp vs I, macro: %s',diag_info{1})])
                legend('I','Itot linear','Itot exp','Itot expVknee','Location','NorthWest')

%        legend('I','Itot linear','Itot exp','Location','NorthWest')
        
        grid on;
        
        
        subplot(3,2,5)
        plot(V+Vsc,I-asm_Iph,'b',V+Vsc,(asm_ion.I+asm_elec.I)+asm_ion.mean(1),'g',V+Vsc,asm_ion.I+asm_expfit.I+asm_ion.mean(1),'r',V+Vsc,asm_Iph,'black')
        axis([min(V)+Vsc max(V)+Vsc min(I) max(I)])
        title([sprintf('Vp vs I, fully auto,lum=%d, %s',illuminated,diag_info{1})])
        legend('I','ion+e(linear)','Ions+e(exp)','pe','Location','Northwest')
        grid on;
        
    end
    
    
catch err
    
    
    
    fprintf(1,'\nlapdog:Analysis Error for %s, \nVguess= %f , illum=%2.1f\n error message:%s\n',diag_info{2},assmpt.Vknee,illuminated,err.message);
    
    
    
    len = length(err.stack);
    if (~isempty(len))
        for i=1:len
            fprintf(1,'%s, %i,',err.stack(i).name,err.stack(i).line);
        end
    end
    
    fprintf(1,'V & I = \n');
    fprintf(1,'%e,',V);
    fprintf(1,'\n');
    fprintf(1,'%e,',Is);
    
    DP.Quality = sum(Q)+200;
    
    fprintf(1,'\nlapdog: continuing analysis...');
    return
    
    
end
end

