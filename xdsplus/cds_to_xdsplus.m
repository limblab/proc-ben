function xds = cds_to_xdsplus(params, cds)

    bin_width = params.bin_width;
    ex = experiment; 
    ex.meta.hasEmg = cds.meta.hasEmg; 
    ex.meta.hasUnits = true;
    ex.meta.hasTrials = true; 
    ex.meta.hasForce = cds.meta.hasForce;
    ex.meta.hasKinematics = cds.meta.hasKinematics;
    ex.binConfig.filterConfig.sampleRate = 1/bin_width;
    ex.firingRateConfig.sampleRate = 1/bin_width;
    ex.firingRateConfig.method = 'bin';
    ex.addSession(cds);
    ex.calcFiringRate;

    ex.binConfig.include(1).field = 'units';
    field_ind = 2;
    if ex.meta.hasEmg == true
       ex.emg.processDefault;
       ex.binConfig.include(field_ind).field = 'emg';
       field_ind = field_ind + 1;
    end

    if ex.meta.hasKinematics == true
       ex.binConfig.include(field_ind).field = 'kin';
       field_ind = field_ind + 1;
    end

    if ex.meta.hasForce == true
       ex.binConfig.include(field_ind).field = 'force';
    end
    ex.binData;

    xds.meta = cds.meta;
    xds.bin_width = bin_width;
    xds.time_frame = ex.bin.data.t;
    xds.has_EMG = xds.meta.hasEmg;
    xds.has_force = xds.meta.hasForce;
    xds.has_kin = xds.meta.hasKinematics;
    xds.sorted = params.sorted;

    % units
    elec_mask = zeros(length(cds.units), 1);
    for i = 1:length(cds.units)
        if strfind(cds.units(i).label,'elec') == 1
            elec_mask(i) = 1;
        end
    end

    if params.sorted == 0
        good_id = find(elec_mask == 1);
        for i = 1:length(good_id)
            xds.unit_names{1,i} = cds.units(good_id(i)).label;
            xds.spikes{1,i} = cds.units(good_id(i)).spikes.ts;
            %xds.spike_waveforms{1,i} = cds.units(good_id(i)).spikes.wave;
        end
        [~,binnedUnitMask] = ex.bin.getUnitNames;
        bad_id = find(elec_mask == 0);
        temp1 = find(binnedUnitMask == 1);
        for i = 1:length(bad_id)
            binnedUnitMask(temp1(bad_id(i))) = 0;
        end
    elseif params.sorted == 1
        disp('Sorted version will be served later');
    end

    xds.spike_counts = ex.bin.data{:,binnedUnitMask}*bin_width;
    if ex.meta.hasEmg == true
       emgMask = ~cellfun(@(x)isempty(strfind(x,'EMG')),ex.bin.data.Properties.VariableNames);
       emgNames = ex.bin.data.Properties.VariableNames(emgMask);
       xds.EMG = ex.bin.data{:,emgMask};
       xds.EMG_names = emgNames;
    end
    if ex.meta.hasForce == true
       fxMask = ~cellfun(@(x)isempty(strfind(x,'fx')),ex.bin.data.Properties.VariableNames);
       fyMask = ~cellfun(@(x)isempty(strfind(x,'fy')),ex.bin.data.Properties.VariableNames);
       xds.force(:, 1) = ex.bin.data{:,fxMask};
       xds.force(:, 2) = ex.bin.data{:,fyMask};  
    end
    if ex.meta.hasKinematics == true
       xMask = ~cellfun(@(x)isempty(strfind(x,'x')),ex.bin.data.Properties.VariableNames);
       yMask = ~cellfun(@(x)isempty(strfind(x,'y')),ex.bin.data.Properties.VariableNames);
       temp = find(xMask==1);
       for i = 2:length(temp)
           xMask(temp(i)) = 0; 
       end
       temp = find(yMask==1);
       for i = 2:length(temp)
           yMask(temp(i)) = 0; 
       end
       vxMask = ~cellfun(@(x)isempty(strfind(x,'vx')),ex.bin.data.Properties.VariableNames);
       vyMask = ~cellfun(@(x)isempty(strfind(x,'vy')),ex.bin.data.Properties.VariableNames);
       axMask = ~cellfun(@(x)isempty(strfind(x,'ax')),ex.bin.data.Properties.VariableNames);
       ayMask = ~cellfun(@(x)isempty(strfind(x,'ay')),ex.bin.data.Properties.VariableNames);
       xds.kin_p(:, 1) = ex.bin.data{:, xMask};
       xds.kin_p(:, 2) = ex.bin.data{:, yMask};
       xds.kin_v(:, 1) = ex.bin.data{:, vxMask};
       xds.kin_v(:, 2) = ex.bin.data{:, vyMask};
       xds.kin_a(:, 1) = ex.bin.data{:, axMask};
       xds.kin_a(:, 2) = ex.bin.data{:, ayMask};
    end   

    % trial information
    xds.trial_info_table_header = fieldnames(cds.trials);
    xds.trial_info_table = table2cell(cds.trials);

    xds.trial_gocue_time = deal_trial_info('goCue', cds);
    xds.trial_start_time = deal_trial_info('startTime', cds);
    xds.trial_end_time = deal_trial_info('endTime', cds);
    xds.trial_result = deal_trial_info('result', cds);
    xds.trial_target_dir = deal_trial_info('tgtDir', cds);
    xds.trial_target_corners = deal_trial_info('Corners', cds);
    
    %check if CDS has analog and units, and if it does, put it in
    
    if cds.meta.hasAnalog == true
        xds.analog = cds.analog;
    end
    
    if cds.meta.hasUnits == true
        xds.units.spikes = table; 
        for i = 1:length(cds.units)
            xds.units(i).chan = cds.units(i).chan;
            xds.units(i).ID = cds.units(i).ID ;
            xds.units(i).spikes(:, 1) = cds.units(i).spikes(:, 1);
            xds.units(i).array = cds.units(i).array; 
            xds.units(i).lowThreshold = cds.units(i).lowThreshold;
            xds.units(i).highThreshold = cds.units(i).highThreshold;
            xds.units(i).lowPassCorner = cds.units(i).lowPassCorner;
            xds.units(i).lowPassOrder = cds.units(i).lowPassOrder;
            xds.units(i).lowPassType = cds.units(i).lowPassType;
            xds.units(i).highPassCorner = cds.units(i).highPassCorner;
            xds.units(i).highPassOrder = cds.units(i).highPassOrder;
            xds.units(i).highPassType = cds.units(i).highPassType; 
        end
        
        for i = 1:length(xds.units)
            if strcmpi(xds.units(i).spikes.Properties.VariableNames{1}, 'Var1')
                xds.units(i).spikes.Properties.VariableNames{1} = 'ts';
            end
        end
    else
        disp("The CDS file this is converting from doesn't have the units section, so if you put this XDS onto the database it won't be convertible to TD.")
    end
             
                
        
        

    clear cds
    clear ex
    
end

function trial_info = deal_trial_info(str,cds)

    trial_mask = ~cellfun(@(x)isempty(strfind(x,str)),cds.trials.Properties.VariableNames);
    if sum(trial_mask) == 0
        disp('Something is wrong with the trial table');
        trial_info = 0;
    else 
        trial_info = cds.trials{:, trial_mask};
    end
    
end