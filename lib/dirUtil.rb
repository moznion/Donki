module DirUtil
  def switchDirectory(dir)
    defaultPath = './'  # FIXME

    if dir.nil?
      return defaultPath
    end

    makeNotExistDir(dir)
    return dir
  end

  def makeNotExistDir(dir)
    unless FileTest::directory?(dir)
      Dir::mkdir(dir)
    end
  end

  def removeTrailSlash(str)
    str.sub(%r!/$!, '')
  end

  def insertSlash(parent, child)
    removeTrailSlash(parent) + '/' + child
  end

  def getRepoName(repo_fullpath)
    repo_fullpath.split('/')[-1].sub(/\.git$/, '')
  end

  def removeDir(dir)
      FileUtils.remove_entry_secure(dir, true)
  end
end
