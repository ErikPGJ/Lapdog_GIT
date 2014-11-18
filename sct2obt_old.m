% // Convert SCT time to an OBT string
% // Due to the fact that the point . in:
% //
% // SPACECRAFT_CLOCK_START/STOP_COUNT="1/21339876.237"
% //
% // is not a decimal point.. (NOT specified in PDS) but now specified
% // in PSA to be a fraction of 2^16 thus decimal .00123 seconds is stored as
% // 0.123*2^16 ~ .81
% //
% That's Reine's calculation, although I supect it is wrong, the actual
% calculation should be 0.00123*2^6/100000
function obt = sct2obt(value)

integ = floor(value);
frac = value-integ;

obt = integ +(frac*2^16) /100000;

end