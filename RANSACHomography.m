function [BestIndex, BestH]=RANSACHomography(InlierThreshold,Pt1, Pt2)
    DataSize = size(Pt1,1);
    SampleSize = 4;
    InlierProbability = 0.99;
    N=500;
    MinStd = 10^5;
    BestIndex = [];
    BestH = [];
    % InlierThreshold = 15;
    i=1;
    while(1)
        InlierIndex =[];
        Idxs = randperm(DataSize,SampleSize);
        SPt1 = Pt1(Idxs,:);
        SPt2 = Pt2(Idxs,:);
        Colin = CheckCollinearity(SPt1, SPt2);
        if(Colin==1)
            continue;
        end
        A = zeros(2*4,9);
        for(k=1:4)
            A(2*k-1:2*k,:)=...
                [SPt1(k,:) 1 0 0 0 -SPt2(k,1)*[SPt1(k,:) 1];...
                 0 0 0 SPt1(k,:) 1 -SPt2(k,2)*[SPt1(k,:) 1]];
        end
        [U S V] = svd(A);
        h = V(:,end);
        H = reshape(h,[3 3]);
        H = H';

        DistMat=zeros(DataSize,1);

        for k=1:DataSize
            Project = H*[Pt1(k,:)'; 1];
            Project = Project/Project(3);
            Project = Project(1:2,1)';
            Dist = norm(Pt2(k,:)-Project);

            InvProject = inv(H)*[Pt2(k,:)'; 1];
            InvProject = InvProject/InvProject(3);
            InvProject = InvProject(1:2,1)';
            InvDist = norm(Pt1(k,:)-InvProject);
            DistMat(k,1)=Dist+InvDist;

            if Dist+InvDist<InlierThreshold
                InlierIndex=[InlierIndex;k];
            end
        end

        if i>2
            if size(InlierIndex,1)>size(BestIndex,1)
                if std(DistMat)<MinStd
                    BestIndex = InlierIndex;
                    BestH=H;
                end
            end
        end

        if ~isempty(BestIndex)
            m = size(BestIndex,1);
            e = 1-m/DataSize;
            N = log10(1-InlierProbability)/log10(1-(1-e)^4);
        end
        i=i+1;
        if N<i
            break
            %Maximum iteration : 10000
        elseif i>10000
            break
        end
    end
end

function Colin = CheckCollinearity(Sp1,Sp2)
    Corr1 = corr(Sp1(:,1),Sp1(:,2));
    Corr2 = corr(Sp2(:,1),Sp2(:,2));
    if(Corr1>0.8 || Corr2>0.8)
        Colin =1;
    else
        Colin = 0;
    end
end