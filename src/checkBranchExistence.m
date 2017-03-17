function branchExists = checkBranchExistence(branchName)
% The COBRA Toolbox: Development tools
%
% PURPOSE: checks if a branch exists locally
%

    global gitConf
    global gitCmd

    % change the directory to the local directory of the fork
    cd(gitConf.fullForkDir);

    % retrieve a list of all the branches
    [status, result] = system(['git show-ref refs/heads/', branchName]);

    if isempty(result)
        branchExists = false;
    else
        branchExists = true;
    end
end
