%% demo background acquisition (30 seconds of data)
% this script was created following the guidelines provided by NI and
% Matlab to connect to an available NI device and record a fixed length of
% data in the background.
clear all; close all; clc

%% Discover all available devices
% run this script if you want to eventually create a list of connected
% devices. This is useful if the name of your device needs to be selected
% by the user:

% In our case, we need to verify that the device that we expect to connect
% to in the remainder of this code actually exists. If it does not, then we
% need to return a warning to the user
fprintf('discovering available ni devices... ')
d = daqlist("ni");

% designate the expected device name for autoconnect
devID = 'Dev1'; % this is the name for the device that we want to connect to
ix = ismember(d{:,"DeviceID"},devID,'rows'); % return a column of logicals indicating the index of a matching device

if any(ix)
    % if any of the indicies match, automatcally connect to this device
    % create an ni daq channel called dq
    fprintf('%s successfully connected!\n',devID) 
    dq = daq("ni");
    dq.Rate = 20000; % the default is 1000 scans/second
    
    % add the appropriate analog channels for auto connect
    ai_pulse = addinput(dq,devID,"ai0","Voltage");
    ai_voltage = addinput(dq,devID,"ai1","Voltage");
   
    % During a background acquisition, the DataAcquisition can handle 
    % acquired data in a specified way using the ScansAvailableFcn
    % property.
    fprintf('reading data from %s...\n ',devID)
    dq.ScansAvailableFcn = @(src,evt) plotDataAvailable(src, evt);
    
    % By default, the ScansAvailableFcn is called 10 times per second. 
    % Modify the ScansAvailableFcnCount property to decrease the call 
    % frequency. The ScansAvailableFcn will be called when the number of 
    % points accumulated exceeds this value. Set the ScansAvailableFcnCount
    % to the rate, which results in one call to ScansAvailableFcn per 
    % second.
    dq.ScansAvailableFcnCount = floor(dq.Rate/10);
    
    % start the background acquisition
    start(dq, "Duration", seconds(30))
    
    % print to the command window to essentially "prove that the
    % acquisition is occuring in the background
    while dq.Running
        pause(1)
        fprintf("While loop: Scans acquired = %d\n", dq.NumScansAcquired)
    end

    fprintf("Acquisition stopped with %d scans acquired\n", dq.NumScansAcquired);

else
    warning('%s does not match the name of detected ni devices\naborting acquisition',devID)
    return
end



%% custom plotting functions
% make a plot window and add the data when scans are available to the user
function plotDataAvailable(src, ~)
    [data, timestamps, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
    plot(timestamps, data);
end

%% stop acquisition when event
% this is a function that has not been implemented in this script but was
% provided in the matlab documentation as an example of how to stop the
% acquisition upon a voltage event.
function stopWhenEqualsOrExceedsOneV(src, ~)
    [data, timestamps, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
    if any(data >= 1.0)
        disp('Detected voltage exceeds 1V: stopping acquisition')
        % stop continuous acquisitions explicitly
        src.stop()
        plot(timestamps, data)
    else
        disp('Continuing to acquire data')
    end
end
    