function checkoutBranch(branchName)
% The COBRA Toolbox: Development tools
%
% PURPOSE: checks out a branch named <branchName> locally and remotely
%

    global gitConf
    global gitCmd

    % save the currentDir
    currentDir = strrep(pwd, '\', '\\');

    % change the directory to the local directory of the fork
    cd(gitConf.fullForkDir);

    % retrieve a list of all the branches
    [status_gitBranch, resultList] = system('git branch --list | tr -s "[:cntrl:]" "\n"');

    checkoutFlag = '';

    % check if the current branch is the develop branch
    indexDevelop = strfind(resultList, 'develop');

    [status_gitStatus, result_gitStatus] = system('git status -s');

    if status_gitStatus == 0 && isempty(result_gitStatus) && status_gitBranch == 0 && isempty(indexDevelop)
        if gitConf.verbose
            fprintf([gitCmd.lead, ' [', mfilename, '] The current branch is not the <develop> branch.', gitCmd.fail, gitCmd.trail]);
        end

        % update the fork locally
        updateFork(true);

        % checkout the develop branch
        [status_gitCheckout, result_gitCheckout] = system('git checkout develop');

        if status_gitCheckout == 0 && (contains(resultList, '* develop') || contains(result, 'Already on'))
            if gitConf.verbose
                fprintf([gitCmd.lead, ' [', mfilename, '] The current branch is <develop>.', gitCmd.success, gitCmd.trail]);
            end
        else
            result_gitCheckout
            error([gitCmd.lead, 'An error occurred and the <develop> branch cannot be checked out']);
        end

        % reset the develop branch
        [status_gitReset, result_gitReset] = system('git reset --hard upstream/develop');
        if status_gitReset == 0
            if gitConf.verbose
                fprintf([gitCmd.lead, ' [', mfilename, '] The current branch is <develop>.', gitCmd.success, gitCmd.trail]);
            end
        else
            result_gitReset
            error([gitCmd.lead, 'An error occurred and the <develop> branch cannot be checked out']);
        end

        % make sure that the develop branch is up to date
        [status_gitPull, result_gitPull] = system('git pull origin develop');

        if status_gitPull == 0
            if gitConf.verbose
                fprintf([gitCmd.lead, ' [', mfilename, '] The changes of the <develop> branch of your fork have been pulled.', gitCmd.success, gitCmd.trail]);
            end
        else
            result_gitPull
            error([gitCmd.lead, 'The changes of the <develop> branch could not be pulled.', gitCmd.fail]);
        end
    end

    if ~checkBranchExistence(branchName)
        checkoutFlag = '-b';
    else
        checkoutFlag = '';
    end

    % properly checkout the branch
    [status_gitCheckout, result_gitCheckout] = system(['git checkout ', checkoutFlag, ' ', branchName]);
    [status_gitStatus, result_gitStatus] = system('git status -s');

    if status_gitCheckout == 0 && status_gitStatus == 0 && isempty(result_gitStatus)
        if gitConf.verbose
            fprintf([gitCmd.lead, ' [', mfilename, '] The <', branchName, '> branch has been checked out.', gitCmd.success, gitCmd.trail]);
        end

        % rebase if the branch already existed
        if ~strcmp(checkoutFlag, '-b') && ~contains(branchName, 'develop') && ~contains(branchName, 'master')
            %if there are no unstaged changes
            [status_gitStatus, result_gitStatus] = system('git status -s');

            if status_gitStatus == 0 && isempty(result_gitStatus)

                % perform a rebase
                [status_gitRebase, result_gitRebase] = system(['git rebase develop']);

                if status_gitRebase == 0 && ~contains(result_gitRebase, 'up to date')
                    if gitConf.verbose
                        fprintf([gitCmd.lead, ' [', mfilename, '] The <', branchName, '> branch has been rebased with <develop>.', gitCmd.success, gitCmd.trail]);
                    end

                    % push by force the rebased branch
                    [status_gitPush, result_gitPush] = system(['git push origin ', branchName, ' --force']);
                    if status_gitPush == 0
                        if gitConf.verbose
                            fprintf([gitCmd.lead, ' [', mfilename, '] The <', branchName, '> branch has been pushed to your fork by force.', gitCmd.success, gitCmd.trail]);
                        end
                    else
                        result_gitPush
                        error([gitCmd.lead, ' [', mfilename, '] The <', branchName ,'> branch could not be pushed to your fork.', gitCmd.fail]);
                    end
                else
                    [status_gitRebaseAbort, results_gitRebaseAbort] = system(['git rebase --abort']);

                    if status_gitRebaseAbort == 0
                        fprintf([gitCmd.lead, ' [', mfilename, '] The rebase process has been aborted.', gitCmd.fail, gitCmd.trail]);
                    end

                    % hard reset of an existing branch
                    [status_gitReset, result_gitReset] = system(['git reset --hard origin/', branchName]);
                    if status_gitReset == 0
                        if gitConf.verbose
                            fprintf([gitCmd.lead, ' [', mfilename, '] The <', branchName, '> branch has not been rebased and is up to date.', gitCmd.success, gitCmd.trail]);
                        end
                    else
                        result_gitReset
                        error([gitCmd.lead, ' [', mfilename, '] The <', branchName, '> could not be reset.', gitCmd.fail]);
                    end
                end
            end
        else
            % push the newly created branch to the fork
            [status_gitPush, result_gitPush] = system(['git push origin ', branchName]);

            if status_gitPush == 0
                if gitConf.verbose
                    fprintf([gitCmd.lead, ' [', mfilename, '] The <', branchName, '> branch has been pushed to your fork.', gitCmd.success, gitCmd.trail]);
                end
            else
                result_gitPush
                error([gitCmd.lead, ' [', mfilename, '] The <', branchName, '> branch could not be pushed to your fork.', gitCmd.fail]);
            end
        end
    else
        if gitConf.verbose
            result_gitCheckout
            fprintf([gitCmd.lead, ' [', mfilename, '] The branch <', branchName, '> has not be checked out.', gitCmd.fail, gitCmd.trail]);
        end
    end

    % change back to the current directory
    cd(currentDir);
end
