function out = fitDoubleGamma(freeParams, fixedParams)

mode    = fixedParams{1};

switch mode
    
    case 'initialize'
        
        % init(1):   gamma1 shape
        % init(2):   gauss1 ampl
        % init(3):   gamma2 shape
        % init(4):   gauss2 ampl
        out.opts    = optimset('display','off');
        out.init    = [   6    0.5     10      1];   % Model start params
        out.lb      = [-Inf      0   -Inf   -Inf];   % Lower bound
        out.ub      = [ Inf    Inf    Inf    Inf];   % Upper bound

    case {'optimize', 'prediction'}
        
        tps         = fixedParams{2}(:);
        data        = fixedParams{3}(:);
        
        % check version
        v           = version;
        if contains(v, '2022')
            doubleGamma = @(a,tp) (normalize(gampdf(tp, a(1), 1),'range') .* a(2)) - ...
                (normalize(gampdf(tp, a(3), 1), 'range') .* a(4));
        else
            doubleGamma = @(a,tp) (normalize(gampdf(tp, a(1), 1), 'range', [0 1]) .* a(2)) - ...
                (normalize(gampdf(tp, a(3), 1), 'range', [0 1]) .* a(4));
        end

        pred       = doubleGamma(freeParams, tps);

        if strcmp(mode, 'optimize')
            
            out         = sum((data - pred).^2);
            
        elseif strcmp(mode, 'prediction')
            
            if ~isempty(data)
                out.R2      = 1 - sum((data - pred).^2) / sum((data - mean(data)).^2);
            end
            out.pred        = pred;
            out.data        = data;
            out.tps         = tps;
            out.Model       = doubleGamma;
            out.estParams   = freeParams;
            out.labels      = {'shape1', 'ampl1', 'shape2', 'ampl2'};
            
        end
        
end


