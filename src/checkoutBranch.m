function checkoutBranch(branchName)
% The COBRA Toolbox: Development tools
%
% PURPOSE: checks out a branch named <branchName> locally and remotely
%

    global gitConf
    global gitCmd

    % save the currentDir
    currentDir = strrep(pwd,'\','\\');

    % change the directory to the local directory of the fork
    cd(gitConf.fullForkDir);

    % retrieve a list of all the branches
    [status, resultList] = system('git branch --list');

    checkoutFlag = '';

    % check if the current branch is the develop branch
    indexDevelop = strfind(resultList, 'develop');
    indexStar = strfind(resultList, '*');

    if status == 0 && isempty(indexDevelop) %&& abs(indexDevelop-indexStar) > 10 % colors might be denoted as [32m etc.
        if gitConf.verbose
            fprintf([gitCmd.lead, ' [', mfilename, '] The current branch is not the <develop> branch.', gitCmd.fail, gitCmd.trail]);
        end

        % update the fork locally
        updateFork(true);

        % checkout the develop branch
        [status, result] = system('git checkout develop');

        if status == 0 && (contains(resultList, '* develop') || contains(result, 'Already on'))
            if gitConf.verbose
                fprintf([gitCmd.lead, ' [', mfilename, '] The current branch is <develop>.', gitCmd.success, gitCmd.trail]);
            end
        else
            result
            error([gitCmd.lead, 'An error occurred and the <develop> branch cannot be checked out']);
        end

        % make sure that the develop branch is up to date
        [status, result] = system('git pull origin develop');

        if status == 0
            if gitConf.verbose
                fprintf([gitCmd.lead, ' [', mfilename, '] The changes of the <develop> branch of your fork have been pulled.', gitCmd.success, gitCmd.trail]);
            end
        else
            result
            error([gitCmd.lead, 'The changes of the <develop> branch could not be pulled.', gitCmd.fail]);
        end
    end

    % checkout a new branch if it doesn't exist
    if status == 0 && ~contains(resultList, branchName)
        checkoutFlag = '-b';
    end

    % properly checkout the branch
    [status, result0] = system(['git checkout ', checkoutFlag, ' ', branchName]);

    if status == 0
        if gitConf.verbose
            fprintf([gitCmd.lead, ' [', mfilename, '] The <', branchName, '> branch has been checked out.', gitCmd.success, gitCmd.trail]);
        end

        % rebase if the branch already existed
        if ~strcmp(checkoutFlag, '-b') && ~strcmp(branchName, 'develop') && ~strcmp(branchName, 'master')
            %if there are no unstaged changes
            [status, result] = system('git status -s');

            if status == 0 && isempty(result)
                [status, result1] = system(['git rebase develop']);

                if status == 0 && ~contains(result, 'up to date')
                    if gitConf.verbose
                        fprintf([gitCmd.lead, ' [', mfilename, '] The <', branchName, '> branch has been rebased with <develop>.', gitCmd.success, gitCmd.trail]);
                    end
                    % push by force the rebased branch
                    [status, result2] = system(['git push origin ', branchName, ' --force']);
                    if status == 0
                        if gitConf.verbose
                            fprintf([gitCmd.lead, ' [', mfilename, '] The <', branchName, '> branch has been pushed to your fork by force.', gitCmd.success, gitCmd.trail]);
                        end
                    else
                        result2
                        error([gitCmd.lead, ' [', mfilename, '] The <', branchName ,'> branch could not be pushed to your fork.', gitCmd.fail]);
                    end
                else
                    fprintf([gitCmd.lead, ' [', mfilename, '] The <', branchName, '> branch has not been rebased and is up to date.', gitCmd.success, gitCmd.trail]);
                end
            end
        else
            % push the newly created branch to the fork
            [status, result3] = system(['git push origin ', branchName]);

            if status == 0
                if gitConf.verbose
                    fprintf([gitCmd.lead, ' [', mfilename, '] The <', branchName, '> branch has been pushed to your fork.', gitCmd.success, gitCmd.trail]);
                end
            else
                result3
                error([gitCmd.lead, ' [', mfilename, '] The <', branchName, '> branch could not be pushed to your fork.', gitCmd.fail]);
            end
        end
    else
        result0
        error([gitCmd.lead, ' [', mfilename, '] The branch <', branchName, '> cannot be checked out.', gitCmd.fail]);
    end

    % change back to the current directory
    cd(currentDir);
end
