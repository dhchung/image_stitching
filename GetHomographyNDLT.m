function H=GetHomographyNDLT(Pt1,Pt2)
%Similarity Transform
n = size(Pt1,1);

mean1 = mean(Pt1);
mean2 = mean(Pt2);
Temp1 = Pt1 - repmat(mean1,n,1);
Temp2 = Pt2 - repmat(mean2,n,1);

Temp1 = sqrt(sum(Temp1.^2,2));
Temp2 = sqrt(sum(Temp2.^2,2));

s1 = n*sqrt(2)/sum(Temp1,1);
s2 = n*sqrt(2)/sum(Temp2,1);

t1xy = -s1*mean1;
t2xy = -s2*mean2;

T1 = [s1 0 t1xy(1);0 s1 t1xy(2);0 0 1];
T2 = [s2 0 t2xy(1);0 s2 t2xy(2);0 0 1];

TPt1 = zeros(n,2);
TPt2 = zeros(n,2);

for(i=1:n)
    Temp = T1*[Pt1(i,:)';1];
    TPt1(i,:) = Temp(1:2)';
    Temp = T2*[Pt2(i,:)';1];
    TPt2(i,:) = Temp(1:2)';
end
A = zeros(2*n,9);
for(i=1:n)
    A(2*i-1:2*i,:)=...
        [TPt2(i,:) 1 0 0 0 -TPt1(i,1)*[TPt2(i,:) 1];...
         0 0 0 TPt2(i,:) 1 -TPt1(i,2)*[TPt2(i,:) 1]];
end
[U S V] = svd(A);
h = V(:,end);
H_hat = reshape(h,[3 3]);
H_hat = H_hat';
H = T1\H_hat*T2;
end