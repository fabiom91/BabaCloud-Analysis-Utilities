%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function val = majVote(in)
if sum(isnan(in(:))) < length(in(:))
    in1 = in(~isnan(in(:)));
    if length(unique(in1)) > 1
        [count,values]=hist(in1,unique(in1));
        [Vmax,argmax]=max(count);
        count_tmp = count;
        count_tmp(argmax) = [];
        [Vmaxtmp,argmaxtmp]=max(count_tmp);
        if Vmax == Vmaxtmp
            val = max(values);
        else
            val=values(argmax);
        end
    else
        val = in1(1);
    end
else
    val = NaN;
end
end

