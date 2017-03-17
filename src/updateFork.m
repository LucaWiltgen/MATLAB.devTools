function updateFork(force)
% The COBRA Toolbox: Development tools
%
% PURPOSE: updates the fork and the submodules of the repository
%

    global gitConf
    global gitCmd

    %set force = false by default
    if nargin < 1
        force = false;
    end

    % check first if the fork is correctly installed
    checkLocalFork();

    currentDir = strrep(pwd, '\', '\\');

    % list the branches that should be updated
    branches = {'master', 'develop'};

    % change to the directory of the fork
    cd(gitConf.fullForkDir)

    % initialize and update the submodules
    updateSubmodules();

    % retrieve the status of the git repository
    [status_gitStatus, result_gitStatus] = system('git status -s');

    % only update if there are no local changes
    if status_gitStatus == 0 && isempty(result_gitStatus)

        % retrieve a list of all the branches
        if ispc
            filterColor = '';
        else
            filterColor =  '| tr -s "[:cntrl:]" "\n"';
        end
        [status_gitBranch, resultList] = system(['git branch --list ', filterColor]);

        if status_gitBranch == 0
            % loop through the list of branches
            for k = 1:length(branches)
                % checkout the branch k
                if status_gitBranch == 0 && contains(resultList, branches{k})
                    [status_gitCheckout, result_gitCheckout] = system(['git checkout ', branches{k}]);

                    if status_gitCheckout == 0
                        if gitConf.verbose
                            fprintf([gitCmd.lead, ' [', mfilename, '] The branch <', branches{k}, '> was checked out.', gitCmd.success, gitCmd.trail]);
                        end
                    else
                        result_gitCheckout
                        if gitConf.verbose
                            fprintf([gitCmd.lead, ' [', mfilename, '] The branch <', branches{k}, '> could not be checked out.', gitCmd.fail, gitCmd.trail]);
                        end
                    end
                else
                    [status_gitCheckoutCreate, result_gitCheckoutCreate] = system(['git checkout -b ', branches{k}]);

                    if status_gitCheckoutCreate == 0
                        if gitConf.verbose
                            fprintf([gitCmd.lead, ' [', mfilename, '] The branch <', branches{k}, '> was checked out.', gitCmd.success, gitCmd.trail]);
                        end
                    else
                        result_gitCheckoutCreate
                        if gitConf.verbose
                            fprintf([gitCmd.lead, ' [', mfilename, '] The branch <', branches{k}, '> could not be checked out.', gitCmd.fail]);
                        end
                    end
                end

                % pull eventual changes from other contributors or administrators
                [status_gitFetchOrigin, result_gitFetchOrigin] = system(['git fetch origin ', branches{k}]);  % no pull
                if status_gitFetchOrigin == 0
                    if gitConf.verbose
                        fprintf([gitCmd.lead, ' [', mfilename, '] Changes on ', branches{k},' branch of fork pulled.', gitCmd.success, gitCmd.trail]);
                    end
                else
                    result_gitFetchOrigin
                    error([gitCmd.lead, ' [', mfilename, '] Impossible to pull changes from ', branches{k},' branch of fork.', gitCmd.fail]);
                end

                % fetch the changes from upstream
                [status_gitFetchUpstream, result_gitFetchUpstream] = system('git fetch upstream');
                if status_gitFetchUpstream == 0
                    if gitConf.verbose
                        fprintf([gitCmd.lead, ' [', mfilename, '] Upstream fetched.', gitCmd.success, gitCmd.trail]);
                    end
                else
                    result_gitFetchUpstream
                    error([gitCmd.lead, ' [', mfilename, '] Impossible to fetch upstream.', gitCmd.fail]);
                end

                if ~force
                    % merge the changes from upstream to the branch
                    [status_gitMergeUpstream, result_gitMergeUpstream] = system(['git merge upstream/', branches{k}]);
                    if status_gitMergeUpstream == 0
                        if gitConf.verbose
                            fprintf([gitCmd.lead, ' [', mfilename, '] Merged upstream/', branches{k}, ' into ', branches{k}, '.', gitCmd.success, gitCmd.trail]);
                        end
                    else
                        result_gitMergeUpstream
                        error([gitCmd.lead, ' [', mfilename,'] Impossible to merge upstream/', branches{k}, gitCmd.fail]);
                    end
                end

                if force
                    [status_gitReset, result_gitReset] = system(['git reset --hard upstream/', branches{k}]);
                    if status_gitReset == 0
                        if gitConf.verbose
                            fprintf([gitCmd.lead, ' [', mfilename,'] The ', branches{k}, ' branch of the fork has been reset.', gitCmd.success, gitCmd.trail]);
                        end
                    else
                        result_gitReset
                        error([gitCmd.lead, ' [', mfilename,'] Impossible to reset the branch', branches{k}, ' of the fork.', gitCmd.fail]);
                    end

                    % set the flag for a force push
                    forceFlag = '--force';
                    forceText = ' by force';
                else
                    % set the flag for a force push
                    forceFlag = '';
                    forceText = '';
                end

                % push and asking the password
                system(['git push origin ', branches{k}, ' ', forceFlag, ' -q --dry-run']);

                % second push is to retr
                [status_gitPush, result_gitPush] = system(['git push origin ', branches{k}, ' ', forceFlag]);

                if status_gitPush == 0
                    if gitConf.verbose
                        fprintf([gitCmd.lead, ' [', mfilename,'] The <', branches{k}, '> branch has been updated on the fork', forceText, '.', gitCmd.success, gitCmd.trail]);
                    end
                else
                    result_gitPush
                    error([gitCmd.lead, ' [', mfilename,'] Impossible to update <', branches{k}, '> on your fork (', gitConf.forkURL, ').', gitCmd.fail]);
                end
            end
        else
            resultList
            error([gitCmd.lead, ' [', mfilename,'] Impossible to retrieve the branches of your local fork.', gitCmd.fail]);
        end
    else
        if gitConf.verbose
            fprintf([gitCmd.lead, ' [', mfilename,'] The local fork cannot be updated as you have uncommitted changes.', gitCmd.fail, gitCmd.trail]);
        end
    end

    % change back to the original directory
    cd(currentDir);
end
