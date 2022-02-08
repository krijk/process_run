/// {@canonicalFor prompt.prompt}
/// {@canonicalFor prompt.promptConfirm}
/// {@canonicalFor prompt.promptTerminate}
/// {@canonicalFor shell_utils.shellArgument}
/// {@canonicalFor user_config.userLoadEnv}
/// {@canonicalFor user_config.userLoadEnvFile}
/// {@canonicalFor shell_utils.platformEnvironment}
/// {@canonicalFor shell_utils.shellEnvironment}
/// {@canonicalFor shell_utils.userAppDataPath}
/// {@canonicalFor user_config.userEnvironment}
/// {@canonicalFor shell_utils.userHomePath}
/// {@canonicalFor user_config.userPaths}
library process_run.shell;

export '/dartbin.dart'
    show
        dartVersion,
        dartChannel,
        dartExecutable,
        dartChannelStable,
        dartChannelBeta,
        dartChannelDev,
        dartChannelMaster;

// We reuse io sharedStdIn definition.
export '/src/io/shared_stdin.dart' show sharedStdIn;
export '/src/shell_utils.dart'
    show
        userHomePath,
        userAppDataPath,
        shellArgument,
        shellEnvironment,
        platformEnvironment,
        shellArguments,
        shellExecutableArguments;
export '/src/user_config.dart'
    show userPaths, userEnvironment, userLoadEnvFile, userLoadEnv;

export 'dartbin.dart'
    show
        getFlutterBinVersion,
        getFlutterBinChannel,
        isFlutterSupported,
        isFlutterSupportedSync;
export 'src/lines_utils.dart' show ShellLinesController, shellStreamLines;
export 'src/process_cmd.dart'
    show
        processCmdToDebugString,
        processResultToDebugString,

        /// Deprecated
        ProcessCmd;
export 'src/prompt.dart' show promptConfirm, promptTerminate, prompt;
export 'src/shell.dart' show run, Shell, ShellException;
export 'src/shell_environment.dart'
    show
        ShellEnvironment,
        ShellEnvironmentPaths,
        ShellEnvironmentVars,
        ShellEnvironmentAliases;
export 'src/which.dart' show whichSync, which;
export 'utils/process_result_extension.dart'
    show
        ProcessRunProcessExt,
        ProcessRunProcessResultExt,
        ProcessRunProcessResultsExt;
