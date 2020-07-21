function run()
clc;clear all;close all;
%% Load images

%Image sample #1
% for i = 1:41
%     fprintf("Loading img#%d\n",i);
%     Imgc{i} = imrotate(imread(strcat('Example/Photos_2/',num2str(i),'.jpg')), -90);
% end
% BaseImg = 20;


%Image sample #2
for i = 1:8
    fprintf("Loading img#%d\n",i);
    Imgc{i} = imrotate(imread(strcat('Example/Photos/',num2str(i),'.jpg')), -90);
end
BaseImg = 3;


no_img = size(Imgc,2);
ImgIndices = (1:no_img)';
if(BaseImg>no_img)
    fprintf("Base image number shouldn't be larger than the number of image\n");
    fprintf("Setting the base image as %d\n", no_img);
    BaseImg = no_img;
end
TargetImg = find(BaseImg~=ImgIndices);
InlierThreshold = 15;
width = size(Imgc{1},2);
height = size(Imgc{1},1);

%%Feature Extraction
%FeatureMode : 1: Harris
%              2: SURF
FeatureMode = 2;

%% Extract Features
for(i=1:no_img)
    fprintf("Extracting features from img#%d\n",i);
    Img{i}=rgb2gray(Imgc{i});
    if(FeatureMode ==1)
        Temp1= detectHarrisFeatures(Img{i});
        [Temp2 FPts{i}]=extractFeatures(Img{i},Temp1);
%         Temp3 = extractFeatures(Img{i},FPts{i});
        FDes{i}=Temp2.Features;
    else
        FPts{i}=detectSURFFeatures(Img{i});
        FDes{i}=extractFeatures(Img{i},FPts{i});
    end
    Features{i}.Location = FPts{i}.Location;
    Features{i}.Descriptors = FDes{i};
end

%% Match Features between img i and img i+1
for i=1:no_img-1
    fprintf("Matching img#%d and img#%d\n",i, i+1);
    %Mode 1 : SAD
    %Mode 2 : SSD
    %Mode 3 : NCC
    Mode = 1;
    [Idx1, Idx2] = FeatureMatching(FeatureMode, Mode, ...
                                   Features{i}.Descriptors,...
                                   Features{i+1}.Descriptors);
    MatchedIndices{i}.BaseIdx = Idx1;
    MatchedIndices{i}.TargetIdx = Idx2;
    PTs{i}.BaseLoc = Features{i}.Location(MatchedIndices{i}.BaseIdx,:);
    PTs{i}.TargetLoc = Features{i+1}.Location(MatchedIndices{i}.TargetIdx,:);
    MatchingSize{i} = size(PTs{i}.BaseLoc,1);
end

%% Match features and get inlier matches
for i=1:no_img-1
    fprintf("Finding Homography from img#%d and img#%d\n",i, i+1);
    %Mode 1 : SAD
    %Mode 2 : SSD
    %Mode 3 : NCC
    Mode = 3;
    [Idx1, Idx2] = FeatureMatching(FeatureMode, Mode,...
                                   Features{i}.Descriptors,...
                                   Features{i+1}.Descriptors);
    MatchedIndices{i}.BaseIdx=Idx1;
    MatchedIndices{i}.TargetIdx=Idx2;
    PTs{i}.BaseLoc = Features{i}.Location(MatchedIndices{i}.BaseIdx,:);
    PTs{i}.TargetLoc = Features{i+1}.Location(MatchedIndices{i}.TargetIdx,:);
    MatchingSize{i} = size(PTs{i}.BaseLoc,1);
    
    
    %% Do RANSAC
    if size(PTs{i}.BaseLoc,1)<4
        fprintf('Number of correspondence for img#%d and img#%d is %d\n', i, i+1, size(PTs{i}.BaseLoc,1));
        error('Not enough correspondence for homography RANSAC');
    end
    [Inliers{i}, ~] = RANSACHomography(InlierThreshold, PTs{i}.BaseLoc, PTs{i}.TargetLoc);
    if size(Inliers{i},1)<4
        fprintf('Number of correspondence inliers for img#%d and img#%d is %d\n', i, i+1, size(Inliers{i},1));
        error('Not enough correspondence for Homography');
    end
   
    Outliers{i} = (1:MatchingSize{i})';
    Outliers{i} = setdiff(Outliers{i},Inliers{i});
    H{i}.NDLT=GetHomographyNDLT(PTs{i}.TargetLoc(Inliers{i},:), PTs{i}.BaseLoc(Inliers{i},:));

    
    %% Plot matches
    figure(1);
    imshow([Imgc{i} Imgc{i+1}])
    hold on;
    %Inliers
    plot([PTs{i}.BaseLoc(Inliers{i},1),...
          width+PTs{i}.TargetLoc(Inliers{i},1)]',...
         [PTs{i}.BaseLoc(Inliers{i},2),...
          PTs{i}.TargetLoc(Inliers{i},2)]','b');
        
    %Outliers
    plot([PTs{i}.BaseLoc(Outliers{i},1),...
          width+PTs{i}.TargetLoc(Outliers{i},1)]',...
         [PTs{i}.BaseLoc(Outliers{i},2),...
          PTs{i}.TargetLoc(Outliers{i},2)]','r');

    scatter(Features{i}.Location(:,1),...
        Features{i}.Location(:,2),5,'filled','b');
    scatter(repmat(width,size(FDes{i+1},1),1)+...
        Features{i+1}.Location(:,1),...
        Features{i+1}.Location(:,2),5,'filled','r');
    hold off;
    title('Blue: Inliers, Red: Outliers');
      
    WarpImg(2, Imgc{i}, Imgc{i+1}, H{i}.NDLT);
    drawnow;
end

%% Get Homography
H_Base = zeros(3,3,no_img-1);
fprintf("Calculating homography from each images to base image...\n");
for i=1:size(TargetImg,1)
    ImgIdx = TargetImg(i,1);
    fprintf("Finding Homography from img#%d and img#%d\n",ImgIdx, BaseImg);
    % Ex. Target img = 3, and Img Idx = 1
    % H = H{1}*H{2} since H{1} is homography between image 1 and 2, 
    % H{2} is homography between image 2 and 3
    % so , if ImgIdx < BaseImg, H = H{ImgIdx}*H{ImgIdx+1}*...*H{BaseImg-1)
    % and, if ImgIdx > BaseImg, H = inv(H{ImgIdx-1})*...*H(BaseImg)
    
    if(ImgIdx<BaseImg)
        H_Base(:,:,i) = H{ImgIdx}.NDLT;
        for j = ImgIdx+1:1:BaseImg-1
            H_Base(:,:,i) = H{j}.NDLT*H_Base(:,:,i);
        end
    else
        H_Base(:,:,i) = inv(H{ImgIdx-1}.NDLT);
        for j = ImgIdx-2:-1:BaseImg
            H_Base(:,:,i) = inv((H{j}.NDLT))*H_Base(:,:,i);
        end
    end
end

%% Warp images into base image
fprintf("Warping...\n");
WarpImgs(3,Imgc,ImgIndices,BaseImg,H_Base);

end