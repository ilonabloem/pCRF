function out = fit_pCRF_wHRF(free_params, fixed_params)

mode    = fixed_params{1};

switch mode
    case 'initialize'
        
        % [c50 n rMax offset peak1 weight]
        if isempty(free_params)
            init        = [0.5  2.5    2   -1   5   1];
        else
            init        = free_params;
        end

        lb          = [0    0    0   -Inf    2    0];
        ub          = [1   10   30    Inf   12    1];

        opts        =  optimset('MaxFunEvals', 100000, ...
                            'MaxIter', 100000, ...
                            'display', 'off');
                        
        out.init    = init;
        out.lb      = lb;
        out.ub      = ub;
        out.opts    = opts;
         
    case {'optimize', 'prediction'}
        
        % CRF free parameters
        C50_est     = free_params(1);
        n_est       = free_params(2);
        Ampl_est    = free_params(3);
        base_est    = free_params(4);
        gain1_est   = free_params(5);
        gain2_est   = gain1_est * 2;
        weight_est  = free_params(6);
        
        % Fixed parameters
        I           = fixed_params{2};
        TSeries     = fixed_params{3};
        B           = fixed_params{5};
        ds_factor   = fixed_params{6};
        numRuns     = size(fixed_params{2},2);
        start       = fixed_params{7};
        
        % HIRF
        normSum     = @(x) x./sum(x(:));        
        hrf_t       = 0:(1/ds_factor):20; 
        hirf_pos    = gampdf(hrf_t, gain1_est, 1);
        pos_max     = max(hirf_pos(:));
        hirf_pos    = hirf_pos ./ pos_max;
        hirf_neg    = gampdf(hrf_t, gain2_est, 1) ./ pos_max;
        HIRF        = normSum(hirf_pos - (weight_est .* hirf_neg));
 
        % Simulate time series
        totalTR         = size(TSeries,1);
        MR_R_est        = [];
        Select_TSeries  = [];
        for ii = 1:numRuns

            runI            = I(:,ii);

            % Contrast response function
            R               = ((Ampl_est) * (runI.^n_est) ./ (((runI.^n_est)) + (C50_est.^n_est)));

            % Convolve neural response w/ assumed HIRF, temporally blurring the time
            % series.  We have also added a baseline (B), putting this in arbitrary MR
            % units. 
            R_est_bold      = conv(R + B, HIRF);
            R_est_bold      = R_est_bold(1:size(I,1));

            % downsample to match temporal resolution
            newMR_est       = downsample(R_est_bold(:), ds_factor);

            % Use final fixation period to demean
            meanFixation    = mean(newMR_est(totalTR-start(2):totalTR));
            
            % cut off fixation and adaptation periods to match fMRI data
            sim_TSeries     = newMR_est(start(1)+1:end); %((newMR_est./mean(newMR_est))-1)*100;
            % Compute percent signal change    
            sim_TSeries     = ((sim_TSeries./meanFixation)-1)*100;

            run_TSeries     = TSeries(:,ii);

            % concatenate
            MR_R_est        = cat(1, MR_R_est, sim_TSeries);
            Select_TSeries  = cat(1, Select_TSeries, run_TSeries(start(1)+1:end));
        end
        
        % add a baseline shift to whole timeseries
        est_Tseries     = MR_R_est + base_est;
        
        if strcmp(mode, 'optimize')
            
            % Get goodness of fit for this set of parameters
            % value to minimize.  
            SSE         = sum((est_Tseries - Select_TSeries).^2); 
            out         = SSE;

        elseif strcmp(mode, 'prediction')

            out.R2      = 1 - (sum((est_Tseries - Select_TSeries).^2) / sum((Select_TSeries - mean(Select_TSeries)).^2)); 
            out.Tseries = Select_TSeries;
            out.estTseries   = est_Tseries;
            out.estParams   = cat(1, C50_est, n_est, Ampl_est, base_est, gain1_est, gain2_est, weight_est);
            out.paramLabels = {'C50', 'Slope', 'Ampl', 'Offset', 'hrfgain1', 'hrfgain2', 'hrfweight'};
                            
        end
        
end

