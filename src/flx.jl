using Match

global home = homedir()
global flxdir = home * "/.flx"

function checkDepends()
  prc = run(
    pipeline(
      ignorestatus(`which wget unzip git touch cp rm mono`),
      stdout = Pipe(), stderr = Pipe()
    )
  )
  if prc.exitcode != 0
    println("One or more dependencies not found.")
    exit(1)
  end
end

function gen()
  if !isdir(flxdir)
    println("First run, creating $(flxdir)")
    mkdir(flxdir)
  elseif isdir(flxdir)
    println("Using $flxdir")
  end
end

function getEditor()
  if !isdir(flxdir * "/Editor")
    println("Are you sure you want to download Flax and its templates? [y/n]")
    ans = readline()
    if ans == "n" || ans == "N"
      println("Abort.")
      exit(1)
    end

    println("Getting editor.")
    run(
      `wget vps2.flaxengine.com/store/builds/Package_1_04_06334/FlaxEditorLinux.zip --no-check-certificate`
    )
    println("Unzipping editor.")
    run(
      `unzip FlaxEditorLinux.zip -d $(flxdir)/Editor`
    )
    println("Cleaning.")
    rm("./FlaxEditorLinux.zip")
  elseif isdir(flxdir * "/Editor")
    println("Using $flxdir/Editor")
  end
end

function getSamples()
  if !isdir(flxdir * "/FlaxSamples")
    println("Getting samples.")
    run(
      `git clone https://github.com/FlaxEngine/FlaxSamples $(flxdir)/FlaxSamples`
    )
  elseif isdir(flxdir * "/FlaxSamples")
    println("Using $flxdir/FlaxSamples")
  end
end

function selectShell()
  println("What shell do you use? [fish/bash]")
  ans = readline()
  if ans == "fish"
    run(`touch $(flxdir)/fish`)
  elseif ans == "bash"
    run(`touch $(flxdir)/bash`)
  else
    println("Invalid shell: '$ans'")
    exit(1)
  end
end

function checkShell()
  if isfile(flxdir * "/fish") || isfile(flxdir * "/bash")
    println("Shell already configured.")
  else
    selectShell()
    if isfile(flxdir * "/fish")
      println("Add 'set -ga fish_user_paths $(flxdir)/Editor/Binaries/Editor/Linux/Release' to your fish config.")
    elseif isfile(flxdir * "/bash")
      println("Add 'PATH=\"\$PATH:$(flxdir)/Editor/Binaries/Editor/Linux/Release\" to your .bashrc")
    end
  end
end

function create()
  print("\nProject directory: ")
  dir = readline()
  println("\nAvailable templates:\nNone\nBasic\nFPS\nTPS\nParticles\nPhysics\nGraphics\nMaterials")
  print("\nProject template: ")
  template = readline()

  println("\nInfo:\n  Directory: $dir\n  Template: $template\n")
  println("Are you sure? [y/n]")
  ans = readline()
  if ans == "n" || ans == "N"
    println("Abort.")
    exit(1)
  end

  println("\nCreating project in directory '$dir' with template '$template'.")
  if isdir(dir)
    println("Directory '$dir' already exists. It will be deleted. Are you sure? [y/n]")
    as = readline()
    if as == "n" || as == "N"
      println("Abort.")
      exit(1)
    end
    run(`rm -rf $(dir)`)
  end

  tmp = @match template begin
    "None" => ""
    "Basic" => "BasicTemplate"
    "FPS" => "FirstPersonShooterTemplate"
    "TPS" => "ThirdPersonShooterTemplate"
    "Particles" => "ParticlesFeaturesTour"
    "Physics" => "PhysicsFeaturesTour"
    "Graphics" => "GraphicsFeaturesTour"
    "Materials" => "MaterialsFeaturesTour"
    _ => nothing
  end

  if tmp === nothing
    println("Invalid template: $template")
    exit(1)
  end

  mkdir(dir)

  content = readdir("$(flxdir)/FlaxSamples/$(tmp)")

  for file in content
    run(`cp -R $(flxdir)/FlaxSamples/$(tmp)/$(file) $(dir)`)
  end
  run(`mv $(dir)/$(tmp).flaxproj $(dir)/$(dir).flaxproj`)
  println("Done. Run your project with 'FlaxEditor -project $dir'.")
end

function go(args)
  if length(args) == 0
    println("\nOptions:\n  new-project")
    exit(1)
  end
  if args[1] == "new-project"
    println("Creating a new project.")
    create()
  else
    println("Invalid argument: '$(args[1])'")
  end
end

function main()
  checkDepends()
  gen()
  getEditor()
  getSamples()
  checkShell()
  go(ARGS)
end

main()