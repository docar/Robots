function TimeVector = timeGen( LongTime, ShortTime )

if size(LongTime,1) < length(LongTime)
    LongTime = LongTime';
end

if size(ShortTime,1) < length(ShortTime)
    ShortTime = ShortTime';
end

raw = cellfun(@(x) [repmat(x, length(ShortTime), 1) cell2mat(ShortTime)], LongTime,  'UniformOutput', false);

raw = cellfun(@(x) mat2cell(x, ones(size(x,1),1), size(x,2)), raw,  'UniformOutput', false);

TimeVector = vertcat(raw{:});

end

