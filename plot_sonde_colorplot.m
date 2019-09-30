% to plot ozonesondes/radiosondes using color plot

year=2017;
ystr=num2str(year);

ozone=0;
temperature=1;
wind=0;
RH=0;


if ozone
    %% plot ozonesonce colorplot
    load(['/home/kristof/work/ozonesonde/Eureka/o3sonde_' ystr '.mat'])

    ll=length(f_list);

    hw=5/24; % half width of single sonde plot in time (to allow use of surf)

    alt_lim=2; % altitude limit in km

%     figure();
    figure(99)
    subplot(313)

    % loop over all sonde data
    for i=1:ll

        % load altitude grid and ozone vmr
        o3=sonde_data.(f_list{i})(:,2);
        alt=sonde_data.(f_list{i})(:,1);

        % get list of launch times in fractional date
        [ft,year]=fracdate([launchtime{i,1} ' ' launchtime{i,2}],'yyyy-mm-dd HH:MM:SS');

        % convert to days of march
        if any([2000, 2004, 2008, 2012, 2016]==year)
            subtract=60;
        else
            subtract=59;
        end
        
        subtract=1;

        % get correct limits and convert to day of the year
        % create arrays to allow color plot, and implement altitude limit
        ft=[ft-hw:hw:ft+hw]+1-subtract;

        alt=alt(alt<alt_lim*1000)./1000; % convert to km
        o3=o3(alt<alt_lim*1000)*1e9; % convert to ppb

        o3=[o3,o3,o3];
        alt=[alt,alt,alt];

        % color plot
        surf(ft,alt,o3,'EdgeColor','None', 'facecolor', 'interp'), hold on
        ylabel('Altitude (km)')
%         xlabel('Days of March, 2017 (UTC)')

        c=colorbar;
        ylabel(c, 'Ozone conc. (ppbv)')

        % set view to see x-y plane from above
        view(2)
        colormap(jet(300))

%         xlim([7,20.1])
%         xlim([1,32])
        
    end
    
    figure()
    load(['/home/kristof/work/ozonesonde/Eureka/o3sonde_' ystr '_interp.mat']);
    
    alt_ind=400; % up to 4km
%     alt_ind=200; % up to 2km
    
    if year==2016
        fd=x-59;
    else
        fd=x-58;
    end
    
%     ind=find(fd>1 & fd<32);

    ind=1:length(fd);
    fd=x;
    
    vmr_arr(vmr_arr>40*1e-9)=40*1e-9;
    
    % some profiles are missing the lowest ~50m, exclude so interpolation looks ok
    surf(fd(ind),y(5:alt_ind)./1000,vmr_arr(5:alt_ind,ind)*1e9,'edgecolor','none','facecolor', 'interp')
    
    view(2)
    colormap('jet');
    c=colorbar;
    
%     xlim([7,21])
    ylim([0.055,4])
    
    ylabel('Altitude (km)')
    xlabel(c,'Sonde O_3 (ppbv)')
        
end

if temperature
    %% plot radiosonde colorplot (teperature)
    
    load(['/home/kristof/work/radiosonde/Eureka/radiosonde_' ystr '_interp.mat']);
    
    if year==2016
        fd=x-59;
    else
        fd=x-58;
    end
    
    ind=find(fd>5 & fd<25);
    
    figure();
    surf(fd(ind),y(1:200)./1000,T_arr(1:200,ind)-273,'edgecolor','none','facecolor', 'interp')
    
    view(2)
    colormap('jet')
    colorbar
    
    xlim([5,25])
    ylim([0,2])
end

if wind
    %% plot radiosonde colorplot (wind speed)
    
    load(['/home/kristof/work/radiosonde/Eureka/radiosonde_wnd_' ystr '_interp.mat']);
    
    if year==2016
        fd=x-59;
    else
        fd=x-58;
    end
    
    ind=find(fd>7 & fd<21);
    if year==2016, ind(ind==28)=[]; end
        
    figure();
    surf(fd(ind),y(1:200)./1000,wspd_arr(1:200,ind),'edgecolor','none','facecolor', 'interp')
    
    ylabel('Altitude (km)')
    
    view(2)
    colormap('jet')
    c=colorbar;
    ylabel(c, 'Wind speed (m/s)')
    
    xlim([7,21])
    ylim([0,2])
end

if RH
    %% plot radiosonde colorplot (wind speed)
    
    load(['/home/kristof/work/radiosonde/Eureka/radiosonde_RH_' ystr '_interp.mat']);
    
    if year==2016
        fd=x-59;
    else
        fd=x-58;
    end
    
    ind=find(fd>7 & fd<21);
    if year==2016, ind(ind==28)=[]; end
        
    surf(fd(ind),y(1:200)./1000,RH_arr(1:200,ind),'edgecolor','none','facecolor', 'interp')
    
    ylabel('Altitude (km)')
    
    view(2)
    colormap('jet')
    c=colorbar;
    ylabel(c, 'RH (%)')
    
    xlim([7,21])
    ylim([0,2])
    
end


