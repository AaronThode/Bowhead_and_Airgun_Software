%%%Review_airgun_plots.m%%%%
%%review_airgun_plots(plot_str)
%   plot_str: 'all', all plots
%              'time_bearing': time, bearing, interval plot only
function review_airgun_plots(plot_str)
close all;fclose('all');
path(path,pwd);


[Icase_str,date_str_local,Site_vector,params_chc,param,junk,junk,DASAR_str_local, ...
    rawdatadir_local,outputdir_local,locationdir_local]=load_local_runparams(mfilename);


% DASAR_str='g'; %Use '*' to process all DASARs
% if ~isempty(findstr(Icase_str,'BP09'))
%     DASAR_str='a';
% end
max_freq=200;
time_inc_cumSEL=10*60;  %Time increment in seconds for cumulative SEL
time_inc_boxplot=datenum(0,0,1,0,0,0); %Time increment to plot histograms...
sampling_interval=datenum(0,0,0,1,0,0);


param=TOC_params_airgun(params_chc);  %Unpack detection parameters from keyword

%param.energy.nstart=12*60*60*1000;
%param.energy.nsamples=1*60*60*1000;
%if ~isempty(findstr(Icase_str,'Shell08'))
%USGS=load('../USGS_airgun_analysis/LSL2008.mat');

%end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%NEVER TOUCH BELOW UNDER NORMAL CIRCUMSTANCES%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for Isite=Site_vector
    close all
    Icase=sprintf(Icase_str,Isite);
    
    [rawdatadir,~,outputdir,param]=load_pathnames(Icase,param);
    
    
    if ~isempty(rawdatadir_local)
        rawdatadir=rawdatadir_local;
    end
    if ~isempty(outputdir_local)
        outputdir=outputdir_local;
    end
    if ~isempty(locationdir_local)
        locationdir=locationdir_local;
    end
    
    %If load_local_runparam has defined variables, override default values...
    [~,date_str,DASAR_str,keyword]=TOC_runs(Icase);
    if ~isempty(date_str_local)
        date_str=date_str_local;
    end
    if ~isempty(DASAR_str_local)
        if ~iscell(DASAR_str_local)
            DASAR_str=DASAR_str_local;
        else
            DASAR_str=DASAR_str_local{Isite};
        end
    end
    
    if strcmp(DASAR_str,'*')
        DASAR_str=upper('abcdefghijklmnopqrstuvwxyz');
    end
    Id=double(DASAR_str)-96;
    date_range=expand_date_range(date_str);
    
    for Idasar=1:length(DASAR_str)
      
        Idot=min(findstr(Icase,'.'))-1;
        if isempty(findstr(Icase_str,'AURAL'))
            
            outputdir_2=sprintf('%s/Site_0%i/%s/morph',outputdir,Isite,Icase(1:Idot));
        else
            outputdir_2=sprintf('%s/Site_%i/%s/morph',outputdir,Isite,Icase(1:Idot));
            
        end
        
        %       peak: [1x6586 double]
        %                    peakF: [1x6586 double]
        %                  t_Malme: [1x6586 double]
        %                SEL_Malme: [1x6586 double]
        %                rms_Malme: [1x6586 double]
        %                  SEL_FFT: [1x6586 double]
        %             SEL_FFT_band: [15x6586 double]
        %             rms_FFT_band: [15x6586 double]
        
        
        tabs=[];
        ctime=[];
        thet=[];
        ICI=[];
        Ifile=[];
        %Inum=[]
        levels.rms_noise=[];
        levels.rms_noise_band=[];
        levels.t_Malme=[];
        levels.SEL_Malme=[];
         
        if exist('levels')&&exist('level_names')
            %level_names=fieldnames(data.airgun_shots.level);
            for I=1:length(level_names)
                levels.(level_names{I})=[];
            end
        end
        keyword.stage=Icase_str(max(findstr(Icase_str,'.')+1):end);
        clear fname_strr
        for I=1:size(date_range,1)
            fprintf('Trying %s ...\n',date_range(I,:));
            if isempty(strfind(Icase_str,'AURAL'))
                for Inumm=0:2
                    fname_strr{Inumm+1}=sprintf('%s/*%s%iT%s*%s_airguns.mat',outputdir_2,...
                        upper(DASAR_str(Idasar)), Inumm, ...
                        date_range(I,:),keyword.stage);
                    
                end
                
                for Inumm=0:2
                    fname=dir(fname_strr{Inumm+1});
                    
                    if length(fname)>0
                        break
                    end
                end
            else
                fname_strr{1}=sprintf('%s/*%s*%s_airguns.mat',outputdir_2, ...
                    date_range(I,:),keyword.stage);
                
                fname=dir(fname_strr{1});
                if length(fname)==0
                    continue
                end
                
            end
            %fprintf('Loading %s\n',fname_str);
            
            
            %if isempty(fname),continue,end
            try
                for Ifile=1:length(fname)
                    disp(fname(Ifile).name);
                    data=load([outputdir_2 '/' fname(Ifile).name]);
                    if isempty(data.airgun_shots.ICI)
                         fprintf('%s has no values\n',fname(Ifile).name);
                        continue
                    else
                        %disp(fname(Ifile).name);
                        fprintf('%s loaded\n',fname(Ifile).name);
                        
                    end
                    if ~exist('level_names')
                        freq_bandwidth=data.airgun_shots.freq_bandwidth;
                        level_names=fieldnames(data.airgun_shots.level);
                        for I=1:length(level_names)
                            levels.(level_names{I})=[];
                        end
                    end
                    
                    ctime=[ctime data.airgun_shots.ctime];
                    tabs=[tabs datenum(1970,1,1,0,0,data.airgun_shots.ctime)];
                    if isempty(findstr(Icase_str,'AURAL'))
                        thet=[thet data.airgun_shots.bearing];
                    end
                    ICI=[ICI data.airgun_shots.ICI'];
                    for J=1:length(level_names)
                        if ~isempty(levels.(level_names{J}))
                            
                            %Check that number of rows is correct (i.e. octave levels may have multiple bands)
                            Imin=min([ size(levels.(level_names{J}),1) size(data.airgun_shots.level.(level_names{J}),1)]);
                            if J==7&&Imin_old(J)~=Imin
                                freq_bandwidth=data.airgun_shots.freq_bandwidth;
                                
                            end
                            levels.(level_names{J})=[ levels.(level_names{J})(1:Imin,:) data.airgun_shots.level.(level_names{J})(1:Imin,:)];
                            Imin_old(J)=Imin;
                        else
                            
                            levels.(level_names{J})=data.airgun_shots.level.(level_names{J});
                            Imin_old(J)=size(levels.(level_names{J}),1);
                        end
                        
                    end
                    levels.rms_noise=[ levels.rms_noise data.airgun_shots.noise.rms];
                    
                    if ~isempty(levels.rms_noise_band)
                        Imin_noise=min([ size(levels.rms_noise_band,1) size(data.airgun_shots.noise.rms_FFT_band,1)]);
                        if Imin_old_noise~=Imin_noise
                            freq_bandwidth_noise=data.airgun_shots.noise.freq_bandwidth;
                            
                        end
                        levels.rms_noise_band=[levels.rms_noise_band(1:Imin_noise,:) data.airgun_shots.noise.rms_FFT_band(1:Imin_noise,:)];
                        Imin_old_noise=Imin_noise;
                    else
                        levels.rms_noise_band=data.airgun_shots.noise.rms_FFT_band;
                        Imin_old_noise=size(levels.rms_noise_band,1);
                    end
                    
                    Ifile=[Ifile I*ones(1,length(data.airgun_shots.ICI))];
                end %Ifile
            catch
                fprintf('Can''t display %s \n',date_range(I,:));
            end
        end  %date_range
        
        %%Compute cumulative metrics.
        time_inc_date=datenum(0,0,0,0,0,time_inc_cumSEL);
        taxis=min(tabs):time_inc_date:max(tabs);
        fractional_presence=zeros(1,length(taxis)-1);
        cumSEL=zeros(1,length(taxis)-1);
        for It=1:(length(taxis)-1)
            Igood=find(tabs>taxis(It)&tabs<=taxis(It+1)&levels.t_Malme>0);
            fractional_presence(It)=sum(levels.t_Malme(Igood))/time_inc_cumSEL;
            cumSEL(It)=sum(levels.SEL_Malme(Igood));
            
        end
        taxis=taxis(1:(end-1));
        
        if length(ICI)<1
            continue
        end
        
        
        %%%%Saved files...
        save(sprintf('Review_airgun_results_%s_%i%s',keyword.stage,Isite,DASAR_str(Idasar)),'levels','tabs', ...
            'Isite','DASAR_str','Icase','taxis','fractional_presence', ...
            'cumSEL','thet','ICI','tabs');
        
        
        %   plot_str: 'all', all plots
        %              'time_bearing': time, bearing, interval plot only
        
        if strcmp(plot_str,'time_bearing')
            plot_bearing_and_interval;
        else
            %%Plot 2D histograms%%%
            
            %First, remove failed results
            Igood=find(levels.t_Malme>0);
            fprintf('%6.2f percent (%i out of %i) detected pulses yielded a duration \n',100*length(Igood)/length(levels.t_Malme),length(Igood),length(levels.t_Malme));
            [~,printname]=hist2D([levels.peakF(Igood); levels.t_Malme(Igood)],0:10:500,0:0.1:5,{'peak freq (Hz)','duration (s)'});
            print('-djpeg',sprintf('airgun_%s_Site%i%s_%s.jpg',printname,Isite,DASAR_str(Idasar),Icase));
            
            [~,printname]=hist2D([thet(Igood); ICI(Igood)],0:10:360,0:2:60,{'bearing (deg)','interval (s)'});
            print('-djpeg',sprintf('airgun_%s_Site%i%s_%s.jpg',printname,Isite,DASAR_str(Idasar),Icase));
            
            try
                [~,printname]=hist2D([20*log10(abs(levels.rms_Malme(Igood))); 10*log10(abs(levels.SNR(Igood)))], ...
                    70:2:140,0:2:40,{'dB re 1 uPa (rms)','SNR (dB)'});
                print('-djpeg',sprintf('airgun_%s_Site%i%s_%s.jpg',printname,Isite,DASAR_str(Idasar),Icase));
                
                [tmp,printname]= hist2D([levels.t_Malme(Igood); 10*log10(abs(levels.SNR(Igood)))], ...
                    0:0.1:5,0:2:40,{'duration (s)','SNR (dB)'});
                print('-djpeg',sprintf('airgun_%s_Site%i%s_%s.jpg',printname,Isite,DASAR_str(Idasar),Icase));
                
                
                Igood=find(cumSEL>0);
                [tmp,printname]= hist2D([fractional_presence(Igood); 10*log10(abs(cumSEL(Igood)))], ...
                    0:0.02:0.5,40:2:150,{'fraction present','cumSEL (dB)'},1);
                print('-djpeg',sprintf('airgun_%s_Site%i%s_%s.jpg',printname,Isite,DASAR_str(Idasar),Icase));
                
                
                %%%%%Plot boxed levels
                plot_levels_boxplot;
                plot_cumulative_levels_boxplot;
                plot_SNR_and_freq_boxplot;
                
            catch
                disp('Problem with SNR');
            end
            
            %%Plot raw data
            try
                plot_SNR_and_maxfreq;
            end
            plot_bearing_and_interval;
            plot_levels;
            plot_cumulative_metrics;
        end
        
        
    end  %IDASAR
end  %Isite


if exist('USGS','var')
    %plot_USGS_data;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%Inner functions%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function plot_cumulative_levels_boxplot
        figure;
        set(gcf,'pos',[-1826         575        1517         466]);
        subplot(2,1,1);
        plot_data_boxplot(taxis,time_inc_boxplot,fractional_presence,[-1 Inf],6);
        hh=ylabel('fraction time present','interp','tex');
        xlabel('Date');
        title(sprintf('Site %i%s, %s',Isite,DASAR_str(Idasar),Icase));
        ylim([0 1])
        
        subplot(2,1,2);
        plot_data_boxplot(taxis,time_inc_boxplot,10*log10(cumSEL),[10 Inf],6);
        hh=ylabel('cum SEL (dB re 1\muPa^2-s)','interp','tex');
        title(sprintf('Cumulative SEL over %i minutes',time_inc_cumSEL/60));
        xlabel('Date');
        ylim([60 140])
        xlimm=xlim;
        
        subplot(2,1,1);
        xlim(xlimm);
        
        
        
        orient landscape
        print('-djpeg',sprintf('airgun_CumMetrics_Site%i%s_%s_boxplot.jpg',Isite,DASAR_str(Idasar),Icase));
    end

    function plot_levels_boxplot
        figure;
        subplot(2,1,1);
        plot_data_boxplot(tabs,time_inc_boxplot,20*log10(abs(levels.rms_Malme)),[10 Inf],6);
        hh=ylabel('rms (dB re 1\muPa)','interp','tex');
        xlabel('Date');
        ylim([60 140])
        
        
        subplot(2,1,2);
        plot_data_boxplot(tabs,time_inc_boxplot,10*log10(abs(levels.SEL_Malme)),[10 Inf],6);
        ylabel('SEL (dB re 1\muPa^2-s)','interp','tex');
        xlabel('Date');
        title(sprintf('Site %i%s, %s',Isite,DASAR_str(Idasar),Icase));
        ylim([60 140])
        print('-djpeg',sprintf('airgun_levels_Site%i%s_%s_boxplot.jpg',Isite,DASAR_str(Idasar),Icase));
    end

    function plot_SNR_and_freq_boxplot
        figure;
        subplot(3,1,1);
        plot_data_boxplot(tabs,time_inc_boxplot,10*log10(abs(levels.SNR)),[1 Inf],6);
        hh=ylabel('SNR (dB)','interp','tex');
        xlabel('Date');
        ylim([0 20])
        title(sprintf('Site %i%s, %s',Isite,DASAR_str(Idasar),Icase));
        
        
        subplot(3,1,2);
        plot_data_boxplot(tabs,time_inc_boxplot,levels.peakF,[5 Inf],6);
        hh=ylabel('peak (Hz)','interp','tex');
        ylim([0 500]);
        xlabel('Date');
        %ylim([60 140])
        
        subplot(3,1,3);
        plot_data_boxplot(tabs,time_inc_boxplot,levels.max_freq,[5 Inf],6);
        ylim([0 500])
        hh=ylabel('max (Hz)','interp','tex');
        xlabel('Date');
        
        print('-djpeg',sprintf('airgun_SNR_Freq_Site%i%s_%s_boxplot.jpg',Isite,DASAR_str(Idasar),Icase));
        
    end

%%%plot_data_boxplot%%%%%



%%%%%%%%%%%%%%%%plot_SNR_and_maxfreq%%%%%%%%%%%%%%%%

    function plot_SNR_and_maxfreq
        figure;set(gcf,'pos',[560   179   938   749])
        subplot(2,1,1);
        plot(tabs,10*log10(abs(levels.SNR)),'k.','markersize',4);
        datetick('x',6);grid on;
        set(gca,'fontweight','bold','fontsize',14)
        
        hh=ylabel('SNR (dB)','interp','tex');
        xlabel('Date');
        title(sprintf('Site %i%s, %s',Isite,DASAR_str(Idasar),Icase));
        %plot_letter_label('a)');
        ylim([0 40])
        
        subplot(2,1,2);
        plot(tabs,levels.max_freq,'ko',tabs,levels.peakF,'bx','markersize',4);
        
        set(gca,'fontweight','bold','fontsize',14)
        datetick('x',6);grid on;
        hh=ylabel('Hz','interp','tex');
        xlabel('Date');
        %plot_letter_label('b)');
        %ylim([60 140])
        legend('Max Freq','Peak PSD');
        orient landscape
        print('-djpeg',sprintf('airgun_SNR_Site%i%s_%s.jpg',Isite,DASAR_str(Idasar),Icase));
    end

%%%%%%%%%%%%%%%%plot_cumulative_metrics%%%%%%%%%%%%%%%%

    function plot_cumulative_metrics
        figure;set(gcf,'pos',[560   179   938   749])
        subplot(2,1,1);
        plot(taxis,fractional_presence,'k.','markersize',8);
        datetick('x',6);grid on;
        set(gca,'fontweight','bold','fontsize',14)
        
        hh=ylabel('fraction time present','interp','tex');
        xlabel('Date');
        title(sprintf('Site %i%s, %s',Isite,DASAR_str(Idasar),Icase));
        %plot_letter_label('a)');
        ylim([0 1])
        
        subplot(2,1,2);
        plot(taxis,10*log10(cumSEL),'k.','markersize',8);
        set(gca,'fontweight','bold','fontsize',14)
        datetick('x',6);grid on;
        hh=ylabel('cum SEL (dB re 1\muPa^2-s)','interp','tex');
        title(sprintf('Cumulative SEL over %i minutes',time_inc_cumSEL/60));
        xlabel('Date');
        %plot_letter_label('b)');
        ylim([60 190])
        orient landscape
        print('-djpeg',sprintf('airgun_CumMetrics_Site%i%s_%s.jpg',Isite,DASAR_str(Idasar),Icase));
    end

%%%%%%%%%%%%%%%%plot_levels%%%%%%%%%%%%%%%%

    function plot_levels
        figure;set(gcf,'pos',[560   179   938   749])
        subplot(2,1,1);
        plot(tabs,10*log10(abs(levels.SEL_Malme)),'k.','markersize',4);
        datetick('x',6);grid on;
        set(gca,'fontweight','bold','fontsize',14)
        
        hh=ylabel('SEL (dB re 1\muPa^2-s)','interp','tex');
        xlabel('Date');
        title(sprintf('Site %i%s, %s',Isite,DASAR_str(Idasar),Icase));
        %plot_letter_label('a)');
        ylim([60 160])
        
        subplot(2,1,2);
        plot(tabs,20*log10(abs(levels.rms_Malme)),'k.','markersize',4);
        set(gca,'fontweight','bold','fontsize',14)
        datetick('x',6);grid on;
        hh=ylabel('rms (dB re 1\muPa)','interp','tex');
        xlabel('Date');
        %plot_letter_label('b)');
        ylim([60 160])
        orient landscape
        print('-djpeg',sprintf('airgun_levels_Site%i%s_%s.jpg',Isite,DASAR_str(Idasar),Icase));
    end

%%%%%%%%%%%%%%%%plot_bearing_and_interval%%%%%%%%%%%%%%%%

    function plot_bearing_and_interval
        figure;set(gcf,'pos',[560   179   938   749])
        
        if ~isempty(thet)
            subplot(2,1,1)
            plot(tabs,thet,'k.','markersize',4);
            set(gca,'ytick',0:30:360);
            set(gca,'fontweight','bold','fontsize',14)
            datetick('x',6);grid on;ylabel('Bearing (deg)');xlabel('Date');
            %plot_letter_label('a)');
            %title(sprintf('%s - %s',date_range(1,:),date_range(end,:)));
            if ~isempty(findstr(Icase_str,'Shell'))
                title(sprintf('Site %i%s, %s',Isite,DASAR_str(Idasar),Icase(1:7)));
            elseif ~isempty(findstr(Icase_str,'BP09'))
                title(sprintf('BP09 Airgun Results: DASAR %s',upper(DASAR_str(Idasar))));
            end
            
            hold on;
            %if ~isempty(findstr(Icase_str,'Shell08'))
            if exist('USGS','var')
                %   plot(USGS.seismic.time,USGS.seismic.bearing{Isite,Id},'ro','markersize',2);
            end
             ylim([0 360])
       
            % ylim([300 360]);
            subplot(2,1,2)
        end
        plot(tabs,ICI,'k.','markersize',4);set(gca,'fontweight','bold','fontsize',14)
        datetick('x',6);grid on;ylabel('Interval (sec)');xlabel('Date');
        %plot_letter_label('b)');
        %title(sprintf('%s - %s',date_range(1,:),date_range(end,:)));
        hold on
        if exist('USGS','var')
            
            plot(USGS.seismic.time,[USGS.seismic.dt;0],'ro','markersize',2);
        end
        orient landscape
        if ~isempty(findstr(Icase_str,'BP09'))
            print('-djpeg',sprintf('BP09_AirgunResults_NA09%s0',upper(DASAR_str(Idasar))));
            saveas(gcf,sprintf('BP09_AirgunResults_NA09%s0.fig',upper(DASAR_str(Idasar))),'fig');
        else
            set(gcf, 'PaperPositionMode', 'auto');
            print('-djpeg',sprintf('airgun_results_Site%i%s_%s.jpg',Isite,DASAR_str(Idasar),Icase));
            saveas(gcf,sprintf('airgun_results_Site%i%s.fig',Isite,DASAR_str(Idasar)),'fig');
        end
        
    end

%%%%%%%%%%%%%%%%plot_levels.m%%%%%%%%%%%%%%%%

    function make_movie
        Ifile_want=Ifile(Igood);  %Values associated with LSL only, length Igood
        %Inum_want=Inum(Igood);
        Icount=1;
        
        for I=1:size(date_range,1)
            Iload=find(Ifile_want==I);
            fprintf('%i hits in file %s \n',length(Iload),date_range(I,:));
            if ~isempty(Iload)
                fname=dir(sprintf('S%i*%s*%s*.snips',Isite,upper(DASAR_str),date_range(I,:)));
                fname_detsum=dir(sprintf('S%i*%s*%s*.detsum',Isite,upper(DASAR_str),date_range(I,:)));
                [data_detsum]=readEnergySummary([fname_detsum.name ], Inf);
                tabs_detsum=datenum(1970,1,1,0,0,data_detsum.ctime);
                tabs_subset=tabs(Igood(Iload));
                %%%[~,Idetsum]=intersect(tabs_detsum,tabs_subset);
                [dummyvar,Idetsum]=intersect(tabs_detsum,tabs_subset);
                [x]=readEnergySnips(fname.name ,Idetsum,'double','cell');
            end
            try
                for J=1:10:length(x)
                    if rem(J,200)==0,fprintf('%6.2f percent done \n',100*J/length(x));end
                    index=Igood(Iload(J));
                    figure(10)
                    param.Nfft=256;
                    spectrogram(x{J}(1,:),hanning(param.Nfft),round(param.ovlap*param.Nfft),param.Nfft,param.Fs,'yaxis');
                    title(sprintf('%s, range %6.2f km bearing %6.2f',datestr(tabs(index),21),range_interp(index)/1000,thet(index)));
                    caxis([40 120]);xlim([0 3]);colorbar
                    figure(10);
                    FF(Icount)=getframe(gcf);
                    Icount=Icount+1;
                    
                end
            catch
                fprintf('Can''t display %s \n',date_range(I,:));
            end
            
            
        end
        
        %movie2avi(FF,'LSL_spectrograms','fps',24);
        
    end

    function y=get_time_series(tabs_in)
        Ifile_want=Ifile(Igood);  %Values associated with LSL only, length Igood
        %Inum_want=Inum(Igood);
        
        for Itime=1:length(tabs_in)
            %%%[~,Itabs(Itime)]=min(abs(tabs_in(Itime)-tabs(Igood)));
            [dummyvar,Itabs(Itime)]=min(abs(tabs_in(Itime)-tabs(Igood)));
        end
        %[~,I_in,Itabs]=intersect(tabs_in,tabs(Igood));
        indicies=unique(Ifile_want(Itabs));
        for Ifiles=1:length(indicies)
            fname=dir(sprintf('S%i*%s*%s*.snips',Isite,upper(DASAR_str),date_range(indicies(Ifiles),:)));
            fname_detsum=dir(sprintf('S%i*%s*%s*.detsum',Isite,upper(DASAR_str),date_range(indicies(Ifiles),:)));
            [data_detsum]=readEnergySummary([fname_detsum.name ], Inf);
            tabs_detsum=datenum(1970,1,1,0,0,data_detsum.ctime);
            %%%[~,Idetsum]=intersect(tabs_detsum,tabs(Igood(Itabs)));
            [dummyvar,Idetsum]=intersect(tabs_detsum,tabs(Igood(Itabs)));
            [y{Ifiles}]=readEnergySnips(fname.name ,Idetsum,'double','cell');
            disp(sprintf('Actual time is %s',datestr(tabs_detsum(Idetsum))));
        end
        
        
        
        
        
    end



    function plot_levels_range
        figure;
        
        
        %%Simple propgation model
        [minr,Ir]=min(range_interp(Igood));
        minSEL=SEL_signal(Ir)
        alphadB=Tristen(75);
        model.R1=400:10:1050;
        model.loss1=5+minSEL-20*log10(model.R1*1000./minr);
        
        model.R2=1050:10:1300;
        model.loss2=105+log10(model.R2/1050)-alphadB.*(model.R2-min(model.R2));
        
        model.R3=800:10:1100;
        model.loss3=105+log10(model.R3/800)-alphadB.*(model.R3-min(model.R3));
        
        %,USGS.seismic.track_names,[100 1000],200);
        if exist('USGS','var')
            USGS.seismic.leg_range=interp1(tabs(Igood),range_interp(Igood),USGS.seismic.leg_time) ;
        end
        
        %%Process data
        range_interval=5; %km
        
        Ir1=find(tabs_signal<7.336609462025317e+05);
        Ir2=find(tabs_signal>7.336609462025317e+05);
        %[SEL_signal,tabs_signal,SEL_bandlimit,tabs_bandlimit]=plot_levels_time;
        [deci.SEL_range1,range_out,Iout]=crude_decimate_uneven(SEL_signal(Ir1),range_interp(Igood_signal(Ir1))/1000,range_interval,'mean');
        [deci.SEL_range2,range_out2,Iout]=crude_decimate_uneven(SEL_signal(Ir2),range_interp(Igood_signal(Ir2))/1000,range_interval,'mean');
        
        Ir1b=find(tabs_bandlimit<7.336609462025317e+05);
        Ir2b=find(tabs_bandlimit>7.336609462025317e+05);
        
        [deci.SEL_band1,range_out,Iout]=crude_decimate_uneven(SEL_bandlimit(Ir1b),range_interp(Igood_bandlimit(Ir1b))/1000,range_interval,'mean');
        [deci.SEL_band2,range_out2,Iout]=crude_decimate_uneven(SEL_bandlimit(Ir2b),range_interp(Igood_bandlimit(Ir2b))/1000,range_interval,'mean');
        
        subplot(3,1,1)
        plot(range_interp(Igood_signal(Ir2))/1000,depth_interp(Igood_signal(Ir2)),'rx', ...
            range_interp(Igood_signal(Ir1))/1000,depth_interp(Igood_signal(Ir1)),'k.','markersize',2);axis('ij')
        set(gca,'fontweight','bold','fontsize',14)
        plot_letter_label('a)');
        grid on;ylabel('depth (m)');xlabel('Range (km)');
        %title(sprintf('%s - %s',date_range(1,:),date_range(end,:)));
        title(sprintf('Site %i%s',Isite,DASAR_str));
        if exist('USGS','var')
            plot_labels(USGS.seismic.leg_range/1000,USGS.seismic.track_names,[100 1000],200);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%Plot range dependence only%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        subplot(3,1,2)
        plot(range_interp(Igood_signal(Ir2))/1000,SEL_signal(Ir2),'bx', ...
            range_interp(Igood_signal(Ir1))/1000,SEL_signal(Ir1),'kx', ...
            'markersize',2);
        set(gca,'fontweight','bold','fontsize',14)
        plot_letter_label('b)');
        grid on;ylabel('SEL dB re 1uPa^2-s');xlabel('Range (km)');
        ylim([80 120]);
        plot_labels(USGS.seismic.leg_range/1000,USGS.seismic.track_names,[80 90],5);
        hold on;
        plot(model.R1,model.loss1,'c-','linewidth',3);
        plot(model.R2,model.loss2,'c--','linewidth',3);
        plot(model.R3,model.loss3,'c--','linewidth',3);
        
        plot(range_out2,deci.SEL_range2,'ro','markerfacecolor','r','markersize',3);
        plot(range_out,deci.SEL_range1,'g^','markerfacecolor','g','markersize',3);
        
        subplot(3,1,3)
        plot(range_interp(Igood_bandlimit(Ir2b))/1000,SEL_bandlimit(Ir2b),'bx', ...
            range_interp(Igood_bandlimit(Ir1b))/1000,SEL_bandlimit(Ir1b),'kx', ...
            'markersize',2);
        set(gca,'fontweight','bold','fontsize',14)
        plot_letter_label('c)');
        grid on;ylabel('SEL dB re 1uPa^2-s');xlabel('Range (km)');
        title(sprintf(' SEL_chc: %s, Cutoff frequency: %6.2f',SEL_chc,max_freq));
        
        ylim([80 120]);
        plot_labels(USGS.seismic.leg_range/1000,USGS.seismic.track_names,[80 90],5);
        hold on;
        plot(range_out2,deci.SEL_band2,'ro','markerfacecolor','r','markersize',3);
        plot(range_out,deci.SEL_band1,'g^','markerfacecolor','g','markersize',3);
        plot(model.R1,model.loss1-5,'c-','linewidth',3);
        plot(model.R2,model.loss2-5,'c--','linewidth',3);
        plot(model.R3,model.loss3-5,'c--','linewidth',3);
        
        
        %title(sprintf('%s - %s',date_range(1,:),date_range(end,:)));
        
        
        orient tall
        print('-djpeg',sprintf('airgun_results_range_%s_Site%i%s',SEL_chc,Isite,DASAR_str));
        saveas(gcf,sprintf('airgun_results_range_%s_Site%i%s.fig',SEL_chc,Isite,DASAR_str),'fig');
        
        function alpha=Thorpe(f)
            f=f/1000;
            alpha=3.3e-3+0.11*(f.^2)./(1+f.^2)+44.*(f.^2)./(4100+f.^2)+(3e-4).*f.^2;
        end
        
        function alpha=Tristen(f)
            alpha=(1.36146e-4)*(f).^1.5;
        end
        
        
    end

    function plot_levels_range2
        
        figure;
        
        
        %%Simple propgation model
        [minr,Ir]=min(range_interp(Igood));
        minSEL=SEL_signal(Ir)
        alphadB=Tristen(75);
        model.R1=400:10:1050;
        model.loss1=5+minSEL-20*log10(model.R1*1000./minr)-Thorpe(75)*(model.R1-min(model.R1));
        
        model.R2=1050:10:1300;
        model.loss2=105+log10(model.R2/1050)-alphadB.*(model.R2-min(model.R2));
        
        model.R3=800:10:1100;
        model.loss3=105+log10(model.R3/800)-alphadB.*(model.R3-min(model.R3));
        
        %,USGS.seismic.track_names,[100 1000],200);
        USGS.seismic.leg_range=interp1(tabs(Igood),range_interp(Igood),USGS.seismic.leg_time) ;
        
        %%Process data
        range_interval=5; %km
        
        Ir1=find(tabs_signal<7.336609462025317e+05);
        Ir2=find(tabs_signal>7.336609462025317e+05);
        %[SEL_signal,tabs_signal,SEL_bandlimit,tabs_bandlimit]=plot_levels_time;
        [deci.SEL_range1,range_out,Iout]=crude_decimate_uneven(SEL_signal(Ir1),range_interp(Igood_signal(Ir1))/1000,range_interval,'mean');
        [deci.SEL_range2,range_out2,Iout]=crude_decimate_uneven(SEL_signal(Ir2),range_interp(Igood_signal(Ir2))/1000,range_interval,'mean');
        
        Ir1b=find(tabs_bandlimit<7.336609462025317e+05);
        Ir2b=find(tabs_bandlimit>7.336609462025317e+05);
        
        [deci.SEL_band1,range_out,Iout]=crude_decimate_uneven(SEL_bandlimit(Ir1b),range_interp(Igood_bandlimit(Ir1b))/1000,range_interval,'mean');
        [deci.SEL_band2,range_out2,Iout]=crude_decimate_uneven(SEL_bandlimit(Ir2b),range_interp(Igood_bandlimit(Ir2b))/1000,range_interval,'mean');
        
        subplot(2,1,1)
        plot(range_interp(Igood_signal(Ir2))/1000,depth_interp(Igood_signal(Ir2)),'rx', ...
            range_interp(Igood_signal(Ir1))/1000,depth_interp(Igood_signal(Ir1)),'k.','markersize',2);axis('ij')
        set(gca,'fontweight','bold','fontsize',14)
        plot_letter_label('a)');
        grid on;ylabel('depth (m)');xlabel('Range (km)');
        %title(sprintf('%s - %s',date_range(1,:),date_range(end,:)));
        title(sprintf('Site %i%s',Isite,DASAR_str));
        plot_labels(USGS.seismic.leg_range/1000,USGS.seismic.track_names,[100 1000],200);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%Plot range dependence only%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        subplot(2,1,2)
        plot(range_interp(Igood_signal(Ir2))/1000,SEL_signal(Ir2),'bx', ...
            range_interp(Igood_signal(Ir1))/1000,SEL_signal(Ir1),'kx', ...
            'markersize',2);
        set(gca,'fontweight','bold','fontsize',14)
        plot_letter_label('b)');
        grid on;ylabel('SEL dB re 1uPa^2-s');xlabel('Range (km)');
        ylim([80 120]);
        plot_labels(USGS.seismic.leg_range/1000,USGS.seismic.track_names,[80 90],5);
        hold on;
        plot(model.R1,model.loss1,'c-','linewidth',3);
        plot(model.R2,model.loss2,'c--','linewidth',3);
        plot(model.R3,model.loss3,'c--','linewidth',3);
        
        plot(range_out2,deci.SEL_range2,'ro','markerfacecolor','r','markersize',3);
        plot(range_out,deci.SEL_range1,'g^','markerfacecolor','g','markersize',3);
        
        %         subplot(3,1,3)
        %         Iclean1=find(levels.t_Malme(Igood_signal(Ir1))>0);
        %         index1=Igood_signal(Ir1(Iclean1));
        %         [deci.td1,range_out,Iout]=crude_decimate_uneven(levels.t_Malme(index1),range_interp(index1)/1000,range_interval,'median');
        %         Iclean2=find(levels.t_Malme(Igood_signal(Ir2))>0);
        %         index2=Igood_signal(Ir2(Iclean2));
        %         [deci.td2,range_out2,Iout]=crude_decimate_uneven(levels.t_Malme(index2),range_interp(index2)/1000,range_interval,'median');
        %
        %
        %          plot(range_interp(index2)/1000,levels.t_Malme(index2),'bx', ...
        %             range_interp(index1)/1000,levels.t_Malme(index1),'kx', ...
        %             'markersize',2);
        %         set(gca,'fontweight','bold','fontsize',14)
        %         plot_letter_label('c)');
        %         grid on;ylabel('duration (s)');xlabel('Range (km)');
        %         %ylim([80 120]);
        %         hold on;
        %
        %         plot(range_out2,deci.td2,'ro','markerfacecolor','r','markersize',3);
        %         plot(range_out,deci.td1,'g^','markerfacecolor','g','markersize',3);
        %         plot_labels(USGS.seismic.leg_range/1000,USGS.seismic.track_names,[1 3],0.5);
        %
        %
        %         %title(sprintf('%s - %s',date_range(1,:),date_range(end,:)));
        %
        
        orient landscape
        print('-dtiffnocompression',sprintf('airgun_results_range_%s_Site%i%s_short',SEL_chc,Isite,DASAR_str));
        
        function alpha=Thorpe(f)
            f=f/1000;
            alpha=3.3e-3+0.11*(f.^2)./(1+f.^2)+44.*(f.^2)./(4100+f.^2)+(3e-4).*f.^2;
        end
        
        function alpha=Tristen(f)
            alpha=(1.36146e-4)*(f).^1.5;
        end
        
        
    end

    function [SEL_signal,tabs_signal,Igood_signal,SEL_bandlimit,tabs_bandlimit,Igood_bandlimit]=plot_levels_time
        %%%%%%%%%%%%%%%%%%%%%%
        %%%Plot Levels%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%
        
        figure
        %%%
        subplot(5,1,1)
        %[ax,h1,h2]=plotyy(USGS.seismic.time,USGS.seismic.depth,USGS.seismic.time,USGS.seismic.dist{Isite,Id}/1000);
        
        set(h1,'linestyle','.','color',[0 0 1],'markersize',2)
        axis('ij');
        set(ax(1),'ytick',0:1000:4000);
        ylim([0 4000]);
        
        set(h2,'linestyle','--','color',[0 1 0],'linewidth',3)
        set(ax(2),'ytick',300:250:1300);
        ylim(ax(2),[300 1300]);
        %axis('ij');
        %ylim([0 4000]);
        for Iax=1:2
            set(ax(Iax),'fontweight','bold','fontsize',14)
            datetick(ax(Iax),'x',6);grid on;
            xlabel(ax(Iax),'Time');
        end
        
        ylabel(ax(1),'depth (m)');
        ylabel(ax(2),'range (km)');
        
        plot_letter_label('a)');
        title(sprintf('Site %i%s',Isite,DASAR_str));
        
        %title(sprintf('%s - %s',date_range(1,:),date_range(end,:)));
        %%Add track and segment names
        plot_labels(USGS.seismic.leg_time,USGS.seismic.track_names,[100 1000],200);
        plot_ice_line(USGS.seismic.leg_time,USGS.seismic.track_names,3000);
        
        
        %%Plot debug plot comparing SEL with and without noise
        %%subtracted...broadband measures
        plot_debug=0;
        
        if plot_debug==1
            make_debug_plots;
        end
        
        %%%
        subplot(5,1,2);
        noise_SEL=levels.t_Malme(Igood).*(levels.rms_noise(Igood)).^2;
        
        if strcmp(SEL_chc,'absolute')
            [deci.SEL,tout,Iout,deci.count.SEL]=crude_decimate_uneven(10*log10(levels.SEL_Malme(Igood)),tabs(Igood),sampling_interval,'mean');
            SEL_signal=10*log10(levels.SEL_Malme(Igood));
        else
            SEL_relative=levels.SEL_Malme(Igood)-noise_SEL;
            SEL_signal=10*log10(SEL_relative);
            
            Iclean=find(~isinf(SEL_signal)&imag(SEL_signal)==0);
            SEL_signal=SEL_signal(Iclean);
            tabs_signal=tabs(Igood(Iclean));
            Igood_signal=Igood(Iclean);
            [deci.SEL,touta,Iout,deci.count.SEL]=crude_decimate_uneven(SEL_signal,tabs_signal,sampling_interval,'mean');
            [deci.std.SEL,touta]=crude_decimate_uneven(SEL_signal,tabs_signal,sampling_interval,'std');
            
            
        end
        noise_SEL=10*log10(noise_SEL);
        Iclean=find(~isinf(noise_SEL)&imag(noise_SEL)==0);
        
        [deci.SEL_noise,toutb,Iout,deci.count.SEL_noise]=crude_decimate_uneven(noise_SEL(Iclean),tabs(Igood(Iclean)),sampling_interval,'mean');
        [deci.std.SEL_noise,toutb]=crude_decimate_uneven(noise_SEL(Iclean),tabs(Igood(Iclean)),sampling_interval,'std');
        
        
        hhh=plot(touta,deci.SEL,'bs', toutb,deci.SEL_noise,'ko','markersize',3);hold on
        %iii=errorbar(tout,deci.SEL,deci.std.SEL,'linestyle','none','color',[0 0 1]);
        
        
        ylim([80 120]);set(gca,'ytick',80:10:120);
        set(gca,'fontweight','bold','fontsize',14)
        datetick('x',6);grid on;ylabel('SEL (dB re 1uPa^2-sec) ','fontsize',10);xlabel('Time');
        %         hl=legend('signal SEL ','noise SEL');
        %         hc=get(hl,'child');
        %         for Ic=1:length(hc)
        %             try
        %                 set(hc(Ic),'markersize',8);
        %             end
        %         end
        plot_letter_label('b)');
        plot_labels(USGS.seismic.leg_time,USGS.seismic.track_names,[100 120],5);
        plot_ice_line(USGS.seismic.leg_time,USGS.seismic.track_names,110);
        title(SEL_chc);
        
        %% %%Plot counts of relevent samples%
        myfig=gcf;
        figure
        plot(touta,deci.count.SEL,'x');
        set(gca,'fontweight','bold','fontsize',14)
        ylim([0 150]);
        line([min(touta) max(touta)],3*30*[1 1]);
        datetick('x',6);grid on;
        xlabel('Time');
        tmp=datevec(sampling_interval);
        ylabel(sprintf('Number of seismic detections over %i minutes',tmp(5)));
        
        figure(myfig)
        
        %%%
        subplot(5,1,3)
        
        noise_SEL_bandlimit=levels.t_Malme(Igood).*sum((levels.rms_noise_band(find(freq_bandwidth<=max_freq),:)).^2,1);
        SEL_absolute_bandlimit=sum(abs(levels.SEL_FFT_band(find(freq_bandwidth<=max_freq),:)));
        
        if strcmp(SEL_chc,'absolute')
            SEL_bandlimit=10*log10(SEL_absolute_bandlimit);
        else
            SEL_bandlimit=10*log10(SEL_absolute_bandlimit-noise_SEL_bandlimit);
            
        end
        noise_SEL_bandlimit=10*log10(abs(noise_SEL_bandlimit));
        
        %Clean up zeros before decimating...
        Iclean=find(~isinf(SEL_bandlimit)&imag(SEL_bandlimit)==0);
        SEL_bandlimit=SEL_bandlimit(Iclean);
        tabs_bandlimit=tabs(Igood(Iclean));
        Igood_bandlimit=Igood(Iclean);
        [deci.SEL_bandlimit,tout1,Iout,deci.count.SEL_bandlimit]=crude_decimate_uneven(SEL_bandlimit,tabs_bandlimit,sampling_interval,'mean');
        [deci.std.SEL_bandlimit,tout]=crude_decimate_uneven(SEL_bandlimit,tabs_bandlimit,sampling_interval,'std');
        
        Iclean=find(~isinf(noise_SEL_bandlimit));
        [deci.noise_SEL_bandlimit,tout2,Iout,deci.count.noise_SEL_bandlimit]=crude_decimate_uneven(noise_SEL_bandlimit(Iclean),tabs(Igood(Iclean)),sampling_interval,'mean');
        [deci.std.noise_SEL_bandlimit]=crude_decimate_uneven(noise_SEL_bandlimit(Iclean),tabs(Igood(Iclean)),sampling_interval,'std');
        
        
        hhh=plot(tout1,deci.SEL_bandlimit,'bs', tout2,deci.noise_SEL_bandlimit,'ko','markersize',3);
        ylim([80 120]);
        set(gca,'fontweight','bold','fontsize',14)
        datetick('x',6);
        set(gca,'ytick',80:10:120);
        grid on;ylabel('SEL (dB re 1uPa^2-sec) ','fontsize',10);xlabel('Time');
        title(sprintf('Cutoff frequency: %6.2f',max_freq));
        
        %         hl=legend('signal SEL bandlimited','noise SEL bandlimited');
        %         hc=get(hl,'child');
        %         for Ic=1:length(hc)
        %             try
        %                 set(hc(Ic),'markersize',8);
        %             end
        %         end
        plot_letter_label('c)');
        
        plot_labels(USGS.seismic.leg_time,USGS.seismic.track_names,[100 120],5);
        plot_ice_line(USGS.seismic.leg_time,USGS.seismic.track_names,110);
        
        %%%%
        subplot(5,1,5);
        Iclean=find(levels.t_Malme(Igood)>0);
        [deci.duration,toutd,Iout,deci.count.duration]=crude_decimate_uneven(levels.t_Malme(Igood(Iclean)),tabs(Igood(Iclean)),sampling_interval,'mean');
        %plot(tout,duration_deci,'k.',tout,duration_deci+duration_std,'rx',tout,duration_deci-duration_std,'rx','markersize',2);
        plot(toutd,deci.duration,'ko','markersize',3);
        set(gca,'fontweight','bold','fontsize',14)
        datetick('x',6);grid on;ylabel('duration (sec)');xlabel('Time');
        plot_letter_label('e)');
        %title(sprintf('%s - %s',date_range(1,:),date_range(end,:)));
        %%Add track and segment names
        hold on
        ylim([0 3])
        plot_labels(USGS.seismic.leg_time,USGS.seismic.track_names,[2 3],.3);
        plot_ice_line(USGS.seismic.leg_time,USGS.seismic.track_names,2);
        
        %%%%
        subplot(5,1,4)
        plot(touta,deci.std.SEL,'bs',toutb,deci.std.SEL_noise,'ko','markersize',3);grid on
        set(gca,'fontweight','bold','fontsize',14)
        ylim([0 10]);
        datetick('x',6);grid on;ylabel('std. deviation(dB)');xlabel('Time');
        plot_letter_label('d)');
        plot_labels(USGS.seismic.leg_time,USGS.seismic.track_names,[6 8],1);
        
        plot_ice_line(USGS.seismic.leg_time,USGS.seismic.track_names,9);
        
        %keyboard
        
        orient tall
        print('-djpeg',sprintf('airgun_results_time_%s_Site%i%s',SEL_chc,Isite,DASAR_str));
        %saveas(gcf,sprintf('airgun_results_time_%s_Site%i%s.fig',SEL_chc,Isite,DASAR_str),'fig');
        
        
        function make_debug_plots
            figure
            
            [deci.SEL_absolute,tout,Iout]=crude_decimate_uneven(10*log10(levels.SEL_Malme(Igood)),tabs(Igood),sampling_interval,'mean');
            
            noise_SEL=levels.t_Malme(Igood).*(levels.rms_noise(Igood)).^2;
            SEL_relative=levels.SEL_Malme(Igood)-noise_SEL;
            
            [deci.SEL_relative,tout,Iout]=crude_decimate_uneven(10*log10(SEL_relative),tabs(Igood),sampling_interval,'mean');
            [deci.SEL_noise,tout,Iout]=crude_decimate_uneven(10*log10(noise_SEL),tabs(Igood),sampling_interval,'mean');
            
            hhh=plot(tout,deci.SEL_absolute,'bs',tout,deci.SEL_relative,'r^', tout,deci.SEL_noise,'ko');
            
            ylim([80 150])
            set(gca,'fontweight','bold','fontsize',14)
            datetick('x',6);grid on;ylabel('SEL (dB re 1uPa^2-sec) ');xlabel('Time');
            hl=legend('Absolute SEL ','Relative SEL ','noise SEL');
            hc=get(hl,'child');
            for Ic=1:length(hc)
                try
                    set(hc(Ic),'markersize',8);
                end
            end
            orient landscape
            print('-djpeg',sprintf('airgun_results_debug_broadband_timevsSEL_Site%i%s',Isite,DASAR_str));
            %%Bandlimited below 200 Hz
            figure
            
            SEL_absolute_bandlimit=sum(abs(levels.SEL_FFT_band(find(freq_bandwidth<=max_freq),:)));
            noise_SEL_bandlimit=levels.t_Malme(Igood).*sum((levels.rms_noise_band(find(freq_bandwidth<=max_freq),:)).^2,1);
            SEL_relative_bandlimit=SEL_absolute_bandlimit-noise_SEL_bandlimit;
            
            [deci.SEL_absolute_bandlimit,tout,Iout]=crude_decimate_uneven(10*log10(abs(SEL_absolute_bandlimit)),tabs(Igood),sampling_interval,'mean');
            [deci.SEL_relative_bandlimit,tout,Iout]=crude_decimate_uneven(10*log10(abs(SEL_relative_bandlimit)),tabs(Igood),sampling_interval,'mean');
            [deci.noise_SEL_bandlimit,tout,Iout]=crude_decimate_uneven(10*log10(abs(noise_SEL_bandlimit)),tabs(Igood),sampling_interval,'mean');
            hhh=plot(tout,deci.SEL_absolute_bandlimit,'bs',tout,deci.SEL_relative_bandlimit,'r^', tout,deci.noise_SEL_bandlimit,'ko');
            ylim([80 150])
            set(gca,'fontweight','bold','fontsize',14)
            datetick('x',6);grid on;ylabel('SEL (dB re 1uPa^2-sec) ');xlabel('Time');
            hl=legend('Absolute SEL bandlimited','Relative SEL bandlimited','noise SEL bandlimited');
            title(sprintf('Cutoff frequency: %6.2f',max_freq));
            hc=get(hl,'child');
            for Ic=1:length(hc)
                try
                    set(hc(Ic),'markersize',8);
                end
            end
            orient landscape
            print('-djpeg',sprintf('airgun_results_debug_bandlimited_timevsSEL_Site%i%s',Isite,DASAR_str));
            
            
            
        end
        
    end

    function plot_spectra_levels
        
        %%%Time-averaged spectra
        figure
        
        tabs_even=floor(min(tabs(Igood))):datenum(0,0,0,1,0,0):ceil(max(tabs(Igood)));
        for Isnap=1:(length(tabs_even)-1)
            Iwant=find(tabs(Igood)>=tabs_even(Isnap)&tabs(Igood)<=tabs_even(Isnap+1));
            SEL_FFT(:,Isnap)=median(levels.SEL_FFT_band(:,Iwant),2);
        end
        %subplot(2,1,2);
        %plot(tabs(Igood),levels.peakF(Igood),'k.','markersize',2);
        imagesc(tabs_even,freq_bandwidth, 10*log10(abs(SEL_FFT)));
        axis('xy'); caxis([40 120]);colorbar('southoutside')
        set(gca,'fontweight','bold','fontsize',14)
        datetick('x',6);grid on;ylabel('Freq(Hz)');xlabel('Time');
        %plot_letter_label('b)');
        title('SEL distribution vs frequency and time');
        %%Add track and segment names
        hold on
        ylim([0 500])
        plot_labels(USGS.seismic.leg_time,USGS.seismic.track_names,[300 400],20,[1 0 0]);
        [peakF,tout,Iout]=crude_decimate_uneven(levels.peakF(Igood_signal),tabs(Igood_signal),datenum(0,0,0,1,0,0),'mean');
        plot(tout,peakF,'ko','markersize',3);
        
        
        orient landscape
        print('-djpeg',sprintf('airgun_results_spectrum_Site%i%s',Isite,DASAR_str));
        saveas(gcf,sprintf('airgun_results_spectrum_Site%i%s.fig',Isite,DASAR_str),'fig');
        
        
    end

    function hhh=plot_ice_line(times,names,yvalue)
        ice.tstart_partial=0;
        ice.tstart_break=0;
        ice.tend=0;
        for LL=1:length(names)
            if ~isempty(findstr(names(LL).name,'06a'))
                ice.tstart_partial=times(LL);
            elseif ~isempty(findstr(names(LL).name,'07b'))
                ice.tstart_break=times(LL);
            end
        end
        ice.tend=times(end);
        
        hl=line([ice.tstart_partial ice.tstart_break],yvalue*[1 1]);
        set(hl,'linestyle','--','color',[1 0 0],'linewidth',2);
        
        h2=line([ice.tstart_break ice.tend],yvalue*[1 1],'color',[1 0 0],'linewidth',2);
        
        
    end

    function hhh=plot_labels(times,names,yrange,yinc,pcolors)
        if ~exist('pcolors')
            pcolors=[0 0 0];
        end
        hold on
        Iplot=0;
        for JJJ=1:length(times)
            Iplot=Iplot+1;
            yplot=min(yrange)+yinc*Iplot;
            %plot(times(JJJ),yplot,'ro');
            h=line(times(JJJ)*[1 1],[0 yplot],'linestyle','--');
            
            if yplot>=max(yrange)
                Iplot=0;
            end
            text(times(JJJ),yplot, names(JJJ).name(6:8),'fontsize',8,'color',pcolors);
            
        end
        
    end

    function plot_letter_label(charr)
        text(-0.15,1.1,charr,'units','norm','fontweight','bold','fontsize',14);
    end

    function plot_USGS_data
        %bearing_interp=interp1(USGS.seismic.time,USGS.seismic.bearing{Isite,Id},tabs);
        bearing_interp=interp1(time,USGS.seismic.bearing{Isite,Id},tabs);
        range_interp=interp1(time,USGS.seismic.dist{Isite,Id},tabs);
        
        Idepth_good=find(USGS.seismic.depth>0);
        depth_interp=interp1(USGS.seismic.time(Idepth_good),USGS.seismic.depth(Idepth_good),tabs);
        
        bdiff=abs(bearing_interp-thet);
        Igood=find(bdiff<20);
        
        %Frequency dependent measures
        levels.SEL_FFT_band=levels.SEL_FFT_band(:,Igood);
        levels.rms_noise_band=levels.rms_noise_band(:,Igood);
        
        
        yes=menu('What now?','Summary plots','Movie','Extract particular date');
        %yes=1;
        if yes==1
            figure(gcf)
            
            
            subplot(2,1,1);hold on
            %plot(tabs,bearing_interp,'kx');
            
            %subplot(2,1,1);
            plot(tabs(Igood),thet(Igood),'g.','markersize',2);
            
            subplot(2,1,2);
            hold on
            plot(tabs(Igood),ICI(Igood),'go','markersize',2);set(gca,'fontweight','bold','fontsize',14)
            
            orient landscape
            print('-djpeg',sprintf('airgun_results_Site%i%s',Isite,DASAR_str));
            saveas(gcf,sprintf('airgun_results_Site%i%s.fig',Isite,DASAR_str(Idasar)),'fig');
            SEL_chc='relative';
            
            
            %%Clean up Igood further, accept only legitimate levels
            [SEL_signal,tabs_signal,Igood_signal,SEL_bandlimit,tabs_bandlimit,Igood_bandlimit]=plot_levels_time;
            plot_levels_range2;
            %plot_spectra_levels;
            
            %SEL_chc='absolute';
            %[SEL_signal,SEL_bandlimit]=plot_levels_time;
            %plot_levels_range;
            
        elseif yes==2
            clear Inum USGS bdiff data depth_interp levels
            
            make_movie;
            
        elseif yes==3
            clear Inum USGS bdiff data depth_interp levels
            
            yes2=1;
            Isnap=0;
            while ~isempty(yes2)
                Isnap=Isnap+1;
                tin(Isnap)=datenum(input('Enter a date as a datevec:'));
                y=get_time_series(tin(Isnap));
                figure
                param.Nfft=256;
                spectrogram(y{1}{1}(1,:),hanning(param.Nfft),round(param.ovlap*param.Nfft),param.Nfft,param.Fs,'yaxis');
                set(gca,'fontweight','bold','fontsize',14);
                caxis([40 120]);xlim([0 3]);colorbar
                xlabel('Time (sec)');ylabel('Frequency (Hz)');
                title(sprintf('%s',datestr(tin(Isnap))))
                orient tall
                print('-djpeg',sprintf('Specgram_%s_Site%i%s',datestr(tin(Isnap),30),Isite,DASAR_str));
                %saveas(gcf,sprintf('Specgram_%s_Site%i%s.fig',datestr(tin(Isnap),30),Isite,DASAR_str),'fig');
                xout{Isnap}=y{1}{1}(1,:);
                
                yes2=input('Another?');
            end
            keyboard;
            
        end
    end

end
