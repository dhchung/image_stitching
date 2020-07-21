function [Idx1 Idx2]=FeatureMatching(FeatureMode,Mode, D1,D2)

if(Mode ==1)
    if(FeatureMode==1)
        DistanceThreshold = 1100;
    else
        DistanceThreshold = 1.0;    
    end
    Distance = pdist2(D1,D2,'CityBlock');

elseif(Mode ==2)
    if(FeatureMode==1)
        DistanceThreshold = 300;
    else
        DistanceThreshold =0.15;
    end
    Distance = pdist2(D1,D2,'Euclidean');
    
elseif(Mode ==3)
    if(FeatureMode==1)
        DistanceThreshold = 0.15;
    else
        DistanceThreshold =0.02;
    end
    Distance = pdist2(D1,D2,'correlation');
end

%Find the match that has minimum distance
[MinDist Min] = min(Distance');
Idx1 = (1:size(D1,1))';
Idx2 = (Min');
%Erase all matches that are over distance threshold
a = find(MinDist>DistanceThreshold);
Idx1(a)=[];
Idx2(a)=[];
MinDist(a)=[];

%Uniquness Test
i=1;
while(i<=size(Idx1,1))
    %Find repeated Idx2
    Temp = find(Idx2(i)==Idx2);
    if(size(Temp,1)>1)
        %If repeated, find the match which has minimum distance
        [TempMin TempMinIdx] = min(MinDist(Temp));
        b = find(TempMinIdx~=1:size(Temp,1));
        %Delete all matches without minimum distance match
        Idx1(Temp(b))=[];
        Idx2(Temp(b))=[];
        MinDist(Temp(b))=[];
    else
        i=i+1;
    end
end

end
