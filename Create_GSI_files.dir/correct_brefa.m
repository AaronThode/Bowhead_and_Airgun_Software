%Place this M-file in a GSI file directory that needs corrections to brefa...
fnames=dir('*.gsi');
brefa=65.3193;
for I=1:length(fnames),
disp(fnames(I).name);
correctgsif_header(fnames(I).name,brefa);
end
