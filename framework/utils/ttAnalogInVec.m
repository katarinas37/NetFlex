function [output] = ttAnalogInVec(inputChannels)
%TTANALOGINVEC inputChannels->Vector of channels to read

if(~isa(inputChannels,'double')|| ~isvector(inputChannels))
    error('Please provide a vector of input channels')
end
output = zeros(size(inputChannels));
for i=inputChannels
   output(i) = ttAnalogIn(i) ;
end
end

