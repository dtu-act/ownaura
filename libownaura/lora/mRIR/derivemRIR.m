function mIR = derivemRIR(irname,ord, flag)

if nargin<3
    flag = 'all';
end
load([irname,'.Early.mat'])
load([irname,'.Late.mat'])
mIR = AddDSERlate(mIRearly,ylate,ord,ord);

switch flag
    case 'all'

    case 'anechoic'
        [m,inL]=max(abs(mIR));
        [k,DSch]=min(inL);
        rms=sqrt(sum(sum(mIR,2).^2));
        mIR=zeros(512,size(mIR,2));
        mIR(256,DSch)=rms;
end