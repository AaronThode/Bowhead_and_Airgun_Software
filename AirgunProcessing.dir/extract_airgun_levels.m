%%%%%%extract_airgun_levels.m%%%%%%%%%%%%%%%%%%
% Routine called by process_one_unit.m to extract level information from
% clips in *.snips file.  Structure similar to evaluate_call_detection2.m
%  Aaron Thode
%  September, 2008
%
% Inputs:
%       Igood: indicies of data_all that contain desired signals.
%           Typically contains indicies of signals that have passed ICI test.
%       data_all: Output of a *detsum file.  Contains fields
%               .ctime: vector of ctimes of detections...
%               .npt:  row vector of duration of signals in samples.
%           Note: data_all contains all data from *.snips file, and Igood
%               is used to select subset.
%       Fs: sampling rate of raw data.
%       bufferTime(s): typically value of param.energy.bufferTime
%               Note that this value may be adjusted if FIR filtering takes place
%       bandwidth:  For use with estimating noise PSD levels
%       filter_bandwidth: filter passband over which to estimate pulse duration...
%           param.airgun.filter_bandwidth=[9 10 450 451];  
%       Nfft,ovlap, used for estimating noise PSD levels
%       run_options:
%               .debug.image_signals:
%               datatype: string, either 'short' or 'double', depending on
%                       data format of snips file...
%               Ncalls:number of signals to load into RAM memory for
%               processing.
%               short_fname: used to ID snips file
%               calibration_keyword:  Used by calibrate_GSI_signal.m to
%                   select calibration scheme for raw data...
%       RawFileName:  Full pathname of raw data file, used to check for
%           clipping
%       dir_out: filter passband over which to estimate pulse duration...
%
%function [airgun_shots]=extract_airgun_levels(Igood,data_all,Fs,bufferTime,bandwidth,  ...
%        Nfft,ovlap,filter_bandwidth,run_options,RawFileName,dir_out)
%
% airgun_shots=extract_airgun_levels(Iguns,data_all,head.Fs, ...
%     bufferTime,param.airgun.bandwidth,param.energy.Nfft,param.energy.ovlap, ...
% 	param.airgun.filter_bandwdith,run_options,fname,param.energy.dir_out);
% 
function [airgun_shots]=extract_airgun_levels(Igood,data_all,Fs,bufferTime,bandwidth,Nfft,ovlap,filter_bandwidth,run_options,RawFileName,dir_out)
persistent Bfilt B_dfilt Imaxx

airgun_shots=[];
bufferTime_org=bufferTime;

if isempty(Igood)
    return
end
%max_clip_count=run_options.max_clip_count;  %Number of clips allowed before data marked as tainted..

debug_snips_check=run_options.debug.snips;

airgun_shots.f_center=[10 20 32 40 50 63 80 100 125 160 200 250 315 395]; %1/3 octave levels
f_band=50;  %Hz
airgun_shots.f_upper=f_band:f_band:500;
airgun_shots.f_upper(end)=495;

%f_low = round(0.707* f_center);
%f_high = round(1.414* f_center);


Icall=0;
best_ctimes=zeros(1,length(Igood));
Bmean=[];
% Option 1:

if length(Igood)<run_options.Ncalls_to_sample
    run_options.Ncalls_to_sample=length(Igood);
end

%scale_factor=get_calibration_scale_factor(run_options.calibration_keyword);

if ~isempty(findstr(run_options.short_fname,'AURAL'))
    Fs_filt=Fs/10;
else
    Fs_filt=Fs;
end
%%Optional prefiltering
%param.airgun.filter_bandwidth
if isempty(Bfilt)&&~isempty(filter_bandwidth)
    %Bfilter = brickwall_bpf(filter_bandwidth,Fs,0);
    
    %Flag feature for max frequency
    for Ifea=1:length(data_all.names)
       if strcmp(data_all.names{Ifea},'max_freq')
          Imaxx=Ifea; 
       end
    end
    for Ifilter=1:length(airgun_shots.f_upper)
        
        filter_bandwidth(3)=airgun_shots.f_upper(Ifilter);
        filter_bandwidth(4)=filter_bandwidth(3)+filter_bandwidth(2)-filter_bandwidth(1);
        disp(sprintf('Building %.0f-%.0f Hz filter',filter_bandwidth(2),filter_bandwidth(3)));
        disp(sprintf('Transition zone bandwidth: %6.2f',filter_bandwidth(2)-filter_bandwidth(1)));
        
        [B_dfilt{Ifilter},Bfilt]=brickwall_bpf(filter_bandwidth,Fs_filt,0);
        %%Bfilt are actual coefficients, B_dfilt is filter object
    end
    disp('Finished building');
else
    disp('Filter already built');
end
tt1=tic;
%disp(sprintf('missing %i calls at end',floor(length(I
fclose('all');


for I=1:ceil(length(Igood)/run_options.Ncalls_to_sample)
%    disp(sprintf('Batch %i of %i',I,ceil(length(Igood)/run_options.Ncalls_to_sample)));
    Iabs=run_options.Ncalls_to_sample*(I-1)+(1:run_options.Ncalls_to_sample);
    Iabs=Iabs(Iabs<=length(Igood));
    Iref=Igood(Iabs);
    snips_name=dir([dir_out '/' run_options.short_fname '*.snips']);
    
    
    %Load data from JAVA program.  Note that a 4th-order Butterworth filter has already been applied, but
    %clipping events have been retained...
    [x,~,~,~,~,~,head]=readEnergySnips([dir_out '/' snips_name.name], Iref,'double','cell','keep_open');
    
    if head.Fs~=Fs
       error('head.Fs does not equal Fs in extract_airgun_levels.m'); 
    end
    
    %Determine raw data offset to determine cliping
    if I==1
       switch head.wordtype
           
%            case 'unit16' % Corrected below by KHK, 13 Feb 2014
           %case 'uint16'
            %   raw_offset=0;
            %   clip_limit=[50 (2^16-1)-50];
           case {'int16','uint16'}
               raw_offset=2^15;
               clip_limit=[50 (2^16-1)-50];
           otherwise
               error(sprintf('need to specify a raw_offset for data type %s',head.wordtype));
       end
        
    end
    
    % disp(sprintf('%6.2f percent done',100*I/(length(Igood)/run_options.Ncalls_to_sample)));
    cstart=data_all.ctime(Iref);
    dstart=diff(cstart);dstart=[0 dstart cstart(end)];
    
    for II=1:length(Iref)
        Icall=Icall+1;
        
        
        if length(x{II}(1,:))<round(Fs* bufferTime_org)  %use original bufferTime because this is the raw data...
            disp('signal shorter than buffer time.');
            % keyboard
            continue;
        end
        
        %%%%Read raw data to check for clipping
        %%%Note that even a filtered file, like a DASARC, will assign a
        %%%clipped value to output even original input data are clipped.
        
        %yraw=(x{II}(1,:)/scale_factor);
        yraw=raw_offset+(x{II}(1,:)/head.scale_factor);
        
        %clip_count=length(find((yraw>=65536-1)|(yraw<65536)));  %Counts number of times signal pegs out.
        clip_count=length(find(yraw-clip_limit(2)>0|yraw<clip_limit(1)));  
        airgun_shots.clipped(Icall)=clip_count;
        
                if clip_count>0
                    subplot(2,1,1)
                    plot(yraw);title(num2str(clip_count));
                    subplot(2,1,2)
                    spectrogram(yraw,hanning(Nfft),ovlap,Nfft,Fs,'yaxis')
                    keyboard
                end
        format long e
        
        
        if debug_snips_check==1  %check snip files
            plot_images;
        end
        %best_ctimes(Icall)=cstart(II);
        airgun_shots.ctime(Icall)=cstart(II);
        airgun_shots.index(Icall)=Iref(II);
        
        %         if abs(datenum(1970,1,1,0,0,cstart(II))-7.333041599074074e+05)<datenum(0,0,0,0,0,10)
        %             keyboard
        %         end
        
        if ~isempty(strfind(run_options.short_fname,'AURAL'))
            yy=decimate(x{II}(1,:),10,'FIR');
        else
            yy=x{II}(1,:);
        end
        yy=yy-mean(yy);
        if ~isempty(Bfilt)
            
            %yy=filter(B_dfilt,[x{II}(1,:) zeros(1,length(Bfilt))]);
            max_freq=data_all.features(Imaxx,Iref(II));
            airgun_shots.level.max_freq(Icall)=max_freq;
            Ifilt=ceil(max_freq/f_band);
            yy=filter(B_dfilt{Ifilt},yy);
            
            
            %yy=filtfilt(B_dfilt,yy);
            
            
            %%WARNING!  UP TO JUNE 21 this was active--cut most of signal...
            %% and messed up dt measurement in get_level_metrics, because buffertime
            %%      not compensated...
            Nf=round(length(Bfilt)/2);
            %yy=yy(Nf:(end-Nf));
            yy=yy(Nf:(end-Nf));
            bufferTime=bufferTime_org-Nf/Fs_filt;
        
            
            %%An exercise to compare different kinds of fitering
%             figure(100);
%             subplot(2,1,1);
%             plot(x{II}(1,:));
%             subplot(2,1,2);
%             plot(filter(B_dfilt{Ifilt},x{II}(1,:)));
%             subplot(3,1,3);
%             plot(filtfilt(B_dfilt{Ifilt},x{II}(1,:)));
            
        end
        
        if length(yy)<round(Fs_filt* bufferTime)  %Changed from Fs to Fs_filt on Feb 11 2014
            disp('filtered signal shorter than buffer time.');
            % keyboard
            continue;
        end
        
        try
            %features=get_level_metrics(yy,Fs_filt, bufferTime, bandwidth,airgun_shots.f_center,cstart(II)); %Debug version
            features=get_level_metrics(yy,Fs_filt, bufferTime, bandwidth,airgun_shots.f_center);
            
            %%%Use below to compare bandpass filtered result with original result...
            
%                         features=get_level_metrics(x{II}(1,:),Fs, bufferTime, bandwidth,airgun_shots.f_center,cstart(II));
%                         subplot(3,1,1)
%                         title(sprintf('Filter span: %i to %i Hz',filter_bandwidth(1),filter_bandwidth(2)));
%                         set(gcf,'pos',[760   657   560   420]);
%                         pause;close all
            
        catch
            disp(sprintf('Get_level_metrics failure at Iref %i\n',Iref(II)));
             keyboard
            continue
           
        end
        
        airgun_shots.level.peak(Icall)=features.peak;
        airgun_shots.level.peakF(Icall)=features.peakF;
        airgun_shots.level.t_Malme(Icall)=features.t_Malme;
        airgun_shots.level.SEL_Malme(Icall)=features.SEL_Malme;
        airgun_shots.level.rms_Malme(Icall)=features.rms_Malme;
        
        %airgun_shots.level.t20dB(Icall)=features.t20dB;
        %airgun_shots.level.SEL20dB(Icall)=features.SEL20dB;
        airgun_shots.level.SEL_FFT(Icall)=features.SEL_FFT;
        airgun_shots.level.SEL_FFT_band(1:length(features.SEL_FFT_band),Icall)=features.SEL_FFT_band;
        airgun_shots.level.rms_FFT_band(1:length(features.rms_FFT_band),Icall)=features.rms_FFT_band;
        airgun_shots.freq_bandwidth=features.freq_bandwidth;
        
        Nbands=length(features.SEL_FFT_third_octave);
        if Nbands>0
            airgun_shots.level.SEL_FFT_third_octave(1:Nbands,Icall)=features.SEL_FFT_third_octave;
            airgun_shots.level.rms_FFT_third_octave(1:Nbands,Icall)=features.rms_FFT_third_octave;
        end
         
        %%%Estimate noise levels preceeding call...
        airgun_shots.noise.rms(Icall)=features.noise.rms;
        airgun_shots.noise.SEL(Icall)=features.noise.SEL;
        airgun_shots.noise.duration(Icall)=features.noise.duration;
        airgun_shots.noise.SEL_FFT_band(1:length(features.noise.SEL_FFT_band),Icall)=features.noise.SEL_FFT_band;
        airgun_shots.noise.rms_FFT_band(1:length(features.noise.rms_FFT_band),Icall)=features.noise.rms_FFT_band;
        airgun_shots.noise.freq_bandwidth=features.noise.freq_bandwidth;
        
        %%%Compute SNR
        % %Must square rms to get intensity units.
        % Subtract one in order to remove noise from signal if rms_Malme does not already subtract noise
        % estimate.
        %airgun_shots.level.SNR(Icall)=(features.rms_Malme./features.noise.rms).^2 -1;  
        airgun_shots.level.SNR(Icall)=(features.rms_Malme./features.noise.rms).^2 ;  
        
        
    end %II, call mark, call
end  %I -- calls
%Closes file...
disp('Finishing extract_airgun_levels');
%[x,nstarts_snips]=readEnergySnips([dir_out '/' snips_name.name], Igood(Iabs),'short','cell');

    function plot_images  %May need to be debugged..
        %[S,F,T,PP1]=spectrogram(y,128,96,128,head.Fs,'yaxis');
        %Debug code: test IIR filter...
        %tlen=2* bufferTime+data_all.npt(1,Iref(II))/Fs;
        %[y{1},t,head]=readsiof(RawFileName,cstart(II)-2* bufferTime,tlen);
        %y{1}=y{1}-mean(y{1});
        
        %y{2}=calibrate_GSI_signal(y{1},'filter');
        %iin=round(Fs* bufferTime)+data_all.npt(1,Iref(II));
        %y{3}=x{II}-mean(x{II});
        y{1}=xorg{II}(1:(length(xorg{II})-round( bufferTime*Fs)));  %snips file
        %y{2}=y0((end-iin):end)-(2^16)/2;
        %y{2}=y0((end-iin):end);  %Direct Siofile download...
        y{3}=x{II};  %MATLAB filtered...
        if ~isempty(y{1}),
            for J=1:3,
                
                %if J<3,y{J}=y{J}((end-iin):end);end
                [S,F,T,PP{J}]=spectrogram(y{J},128,96,128,Fs,'yaxis');
                
            end
            
            for J=1:3,
                figure(4);
                
                subplot(3,1,J);
                imagesc(T,F,10*log10(abs(PP{J})));axis('xy');
                %caxis([-20 50]);
                colorbar;
                switch J
                    case 2
                        caxis([0 70])
                        title(sprintf('Raw Data: %s time to previous %6.2f time to next: %6.2f',datestr(datenum(1970,1,1,0,0,cstart(II))),dstart(II),dstart(II+1)));
                    case 3
                        title(sprintf('MATLAB filtered data, Date: %s time to previous %6.2f time to next: %6.2f',datestr(datenum(1970,1,1,0,0,cstart(II))),dstart(II),dstart(II+1)));
                    case 1
                        title(sprintf('filtered snips index is %i',Iref(II)));
                        caxis([0 70]);
                end
                
                figure(2)
                subplot(3,1,J)
                plot(y{J});grid on;
                
            end
            %keyboard
            yes=input('Continue? (-1 to stop):');
            if yes==-1,
                debug_snips_check=0;
            end
        end
    end  % inner function

end %entire function
