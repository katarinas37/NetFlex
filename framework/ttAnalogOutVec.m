function ttAnalogOutVec(outputChannels, data)
%TTANALOGINVEC inputChannels->Vector of channels to read

if(~isa(outputChannels,'double')|| ~isvector(outputChannels))
    error('Please provide a vector of output channels')
end

if(~isa(data,'double')|| ~isvector(data) || ~numel(data)==numel(outputChannels))
    error('Please provide a vector of output data with same number of entries as in outputChannels')
end
    

for i=1:numel(outputChannels)
   ttAnalogOut(outputChannels(i),data(i));
end

end

