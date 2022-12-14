%%%write_tsv.m%%%%%
%function [fname,Iwrite]=write_tsv(localized,goodName,extension);
%  Based on documentation in WCoutFormat03.doc by Bill McLennan
%  wc0821S508.mat
%
%     end
% end
function [fname,Nwrite]=write_tsv(locations,goodName,extension)

It=max(findstr(goodName{1},'T'))-4;
extension=[extension '_' datestr(now,30)];
fname=['wc' goodName{1}(It:(It+3)) goodName{1}(1:4) '_' extension '.tsv'];
fid=fopen(fname,'w');

Icall=0;
Nwrite=zeros(1,length(goodName));
for I=1:length(locations)
    pos=locations{I}.position;
    
    outcome=lower(pos.outcome);
    Nwrite=Nwrite+sign(locations{I}.ctime_min');
    wctype=-1;
    Icall=Icall+1;
    
    if isempty(findstr(outcome,'successful'))
        pos.ctime=NaN;
        pos.location=[NaN NaN];
        pos.Area=NaN;
        pos.major=NaN;
        pos.minor=NaN;
        pos.Baxis=NaN;
        pos.ellipse_ang=NaN;
        pos.Nused=0;
        pos.Qhat=[0 0 0 0];
        pos.Ikeep=find(~isnan(locations{I}.dt));
        pos.w=zeros(size(locations{I}.Totalfmax));
        fprintf(fid,'%15.2f\t%s\t',pos.ctime,'NaN');
    
    else
       fprintf(fid,'%15.2f\t%s\t',pos.ctime,ctime2str(pos.ctime));
     
    end
    fprintf(fid,'%10.2f\t%10.2f\t%8.4f\t',pos.location(1),pos.location(2),wctype);
    fprintf(fid,'%12.2f\t%12.2f\t%12.2f\t',pos.Area,pos.major,pos.minor);
    %fprintf(fid,'%12.2f\t%12.2f\t%12.2f\t',pos.Area,pos.major,pos.minor);
    fprintf(fid,'%12.4f\t%12.4f\t%i\t',pos.Baxis,pos.ellipse_ang,pos.Nused);
    fprintf(fid,'%12.4f\t',pos.Qhat);
    fprintf(fid,'%s\tautomated\t0\t%s\t',pos.outcome,datestr(now));
    It=min(findstr(goodName{1},'T'))-1;
    for J=1:length(pos.Ikeep)
        Idd=pos.Ikeep(J);
        strr=goodName{Idd}(1:It);
        fprintf(fid,'%s\t%12.8f\t%15.2f\t%15.2f\t%15.2f\t%10.6f\t%10.6f\t%10.6f\t%10.6f\t%10.6f\t%10.6f\t%10.6f\t', ...
            strr,pos.w(J),locations{I}.bearing_rel(Idd),locations{I}.bearing(Idd),locations{I}.ctime_min(Idd), ...
            locations{I}.SEL(Idd),locations{I}.SNR(Idd),locations{I}.Totalfmin(Idd),locations{I}.Totalfmax(Idd), ...
            locations{I}.Totalduration(Idd), locations{I}.bearing_sd(Idd),locations{I}.kappa(Idd));
    end
    fprintf(fid,'\n');
    %
    
end
fclose(fid);
end



function fs = tabfield(s,n)
%mbcharvector(s);
%mbint(n);
if isempty(n)
    fs = '';
elseif length(n) == 1
    xx = find((s == char(9)));
    
    if n > (length(xx) + 1)
        fs = [];
    else
        if isempty(xx)
            fs = s;
        else
            xx = [0;xx(:);length(s) + 1];
            fs = s((xx(n) + 1):(xx(n + 1) - 1));
        end
    end
    fs = strtrim(fs);
else
    fs = cell(size(n));
    for ii = 1:prod(size(n))
        fs{ii} = TabField(s,n(ii));
    end
end
return

end
