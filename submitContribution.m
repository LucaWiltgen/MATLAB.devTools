function contributeFiles(branchName)

    global gitConf
    global gitCmd

    % change the directory to the local directory of the fork
    cd(gitConf.fullForkDir);

    % retrieve a list of remotes
    [status, result] = system('git status -s');

    if status == 0
        arrResult = strsplit(result, '\n');
    else
        error([gitCmd.lead, 'The status of the repository cannot be retrieved', gitCmd.fail, gitCmd.trail]);
    end

    % initialize the array for storing the file names to be added
    addFiles = {};

    addFileOrder = true;

    if length(arrResult) > 10
        reply = input([gitCmd.lead, 'You currently have more than 10 changed files. Are you sure that you want to continue? Y/N [N]: '], 's');

        if isempty(reply) || contains(reply, 'n') || contains(reply, 'N')
            addFileOrder = false;
        end
    end
    if length(arrResult) > 20
        warn([gitCmd.lead, 'You currently have more than 50 new files to add. Consider splitting them into multiple commits (typically only a few files per commit).'])
    end

    if addFileOrder

        countAddFiles = 0;

        % push the file(s) to the repository
        updateFork(false); % silent update

        % get the branch name
        checkoutBranch(branchName);

        for i = 1:length(arrResult)
            tmpFileName = arrResult(i);

            % split the file name into 2 parts
            tmpFileNameChunks = strsplit(tmpFileName{1}, ' ');

            % add deleted files
            if ~isempty(tmpFileName) && contains(tmpFileNameChunks{1}, 'D')
                reply = input([gitCmd.lead, 'You deleted ', tmpFileNameChunks{2:end}, 'Do you want to commit this deletion? Y/N [N]: '], 's');

                if ~isempty(reply) && (strcmp(reply, 'y') || strcmp(reply, 'Y'))
                    countAddFiles = countAddFiles + 1;
                    [status, ~] = system(['git add ', tmpFileNameChunks{2:end}]);
                    if status == 0
                        fprintf([gitCmd.lead, 'The file ', tmpFileNameChunks{2:end}, ' has been added to the stage.', gitCmd.success, gitCmd.trail]);
                    else
                        error([gitCmd.lead, 'The file ', tmpFileNameChunks{2:end}, ' could not be added to the stage.', gitCmd.fail, gitCmd.trail]);
                    end
                end
            end

            % add modified files
            if ~isempty(tmpFileName) && contains(tmpFileNameChunks{1}, 'M')
                reply = input([gitCmd.lead, 'You modified ', tmpFileNameChunks{2:end}, 'Do you want to commit the changes? Y/N [N]: '], 's');

                if ~isempty(reply) && (strcmp(reply, 'y') || strcmp(reply, 'Y'))
                    countAddFiles = countAddFiles + 1;
                    [status, ~] = system(['git add ', tmpFileNameChunks{2:end}]);
                    if status == 0
                        fprintf([gitCmd.lead, 'The file ', tmpFileNameChunks{2:end}, ' has been added to the stage.', gitCmd.success, gitCmd.trail]);
                    else
                        error([gitCmd.lead, 'The file ', tmpFileNameChunks{2:end}, ' could not be added to the stage.', gitCmd.fail, gitCmd.trail]);
                    end
                end
            end

            % add untracked files
            if ~isempty(tmpFileName) && contains(tmpFileNameChunks{1}, '??')
                reply = input([gitCmd.lead, 'Do you want to add the new file ', tmpFileNameChunks{2:end}, '? Y/N [N]: '], 's');
                if ~isempty(reply) && (strcmp(reply, 'y') || strcmp(reply, 'Y'))
                    countAddFiles = countAddFiles + 1;
                    [status, ~] = system(['git add ', tmpFileNameChunks{2:end}]);
                    if status == 0
                        fprintf([gitCmd.lead, 'The file ', tmpFileNameChunks{2:end}, ' has been added to the stage.', gitCmd.success, gitCmd.trail]);
                    else
                        error([gitCmd.lead, 'The file ', tmpFileNameChunks{2:end}, ' could not be added to the stage.', gitCmd.fail, gitCmd.trail]);
                    end
                end
            end
        end

        pushStatus = false;

        % set a commit message
        if countAddFiles > 0
            fprintf([gitCmd.lead, 'You have opted for ', num2str(length(addFiles)), ' files to be added in one commit.', gitCmd.trail]);

            if ~isempty(reply) && (strcmp(reply, 'y') || strcmp(reply, 'Y'))
                commitMsg = input([gitCmd.lead, 'Please enter a commit message (example: "Fixing bug with input arguments"): '], 's');

                if ~isempty(commitMsg)
                    [status, ~] = system(['git commit -m', commitMsg]);
                    fprintf([gitCmd.lead, 'Your commit message has been set.', gitCmd.success, gitCmd.trail]);
                    if status == 0
                        pushStatus = true;
                    else
                        error([gitCmd.lead, 'Your commit message cannot be set.', gitCmd.fail, gitCmd.trail]);
                    end
                else
                    fprintf([gitCmd.lead, 'Please enter a commit message that has more than 10 characters.', gitCmd.fail, gitCmd.trail]);
                end
            end
        end

        % push to the branch in the fork
        if pushStatus
            fprintf([gitCmd.lead, 'Pushing ', num2str(length(addFiles)), ' to your branch <', branchName, '>', gitCmd.trail])
            [status, ~] = system(['git push origin ', branchName, ' --force']);

            if status == 0
                reply = input([gitCmd.lead, 'Do you want to open a pull request (PR)? Y/N [N]: '], 's');

                if ~isempty(reply) && (strcmp(reply, 'y') || strcmp(reply, 'Y'))
                    openPR();
                else
                    fprintf([gitCmd.lead, 'You opted not to submit a pull request (PR). You may open a PR using "openPR()".', gitCmd.trail]);
                end
            else
                error([gitCmd.lead, 'Something went wrong. Please try again.', gitCmd.fail, gitCmd.trail]);
            end
        end
    end
