def parseAsCmdArgs(args) {
    return args.collect { k, v -> "--${k} ${v}" }.join(' ')
}
