function out = processXDSspikes(filename,signal_info)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % this is a direct adaptation of Raeed's processCDSspikes function for
    % xds.
    % 
    % loads an XDS file and returns a field
    spiking_chans  = 1:96;
    exclude_units  = 255; % sort id of units to exclude
    xds_array_name = '';
    assignParams(who,signal_info.params); % overwrite parameters
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % parameter check
    assert(ischar(xds_array_name),'array_name must be a string')
    
    error_flag = false;
    
    % load the XDS
    if ~isempty(filename)
        load(filename);
    else
        error_flag = true;
        disp(['ERROR: ' mfilename ': no filename provided']);
    end
    
    [data, wf] = deal(cell(1,length(xds.units)));
    tmax = 0;
    for unit = 1:length(xds.units)
        data{unit} = xds.units(unit).spikes.ts;
        %wf{unit} = xds.units(unit).spikes.wave; % waveforms aren't supported right now in convertDataToTD
        tmax = max(tmax,xds.units(unit).spikes.ts(end)); % find max timestamp for time vector
    end
    
    % assume right now that the blackrock sampling is 30kHz
    t = (0:1/double(30000):tmax)';
    
    labels = [vertcat(xds.units.chan) vertcat(xds.units.ID)];
    
    % remove unwanted units
    bad_idx = ~ismember(labels(:,1),spiking_chans) | ismember(labels(:,2),exclude_units);
    if ~isempty(xds_array_name)
        bad_idx = bad_idx | ~ismember(cat(2,{xds.units.array})',xds_array_name);
    end
    labels = labels(~bad_idx,:);
    data = data(~bad_idx);
    wf = wf(~bad_idx);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    out.meta   = [];
    out.data   = data;
    out.wf     = wf;
    out.labels = labels;
    out.t      = t;
    out.error_flag = error_flag;
end