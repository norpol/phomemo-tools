{ config
, lib
, pkgs
, ...
}:
let
  phomemo-tools = pkgs.stdenv.mkDerivation rec {
    name = "phomemo-tools";
    pname = "phomemo-tools";
    version = "master";
    src = pkgs.fetchFromGitHub {
      owner = "vivier";
      repo = pname;
      rev = version;
      sha256 = "sha256-Rl8QDEzcBgqBWY+C8UnETDag18gW5pnQsTxXofteJvI=";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];
    buildInputs = with pkgs; [ cups python3Full ];

    CUPS_DATADIR = "${pkgs.cups}/share/cups";
    PYTHONPATH = pkgs.python3Packages.makePythonPath (with pkgs.python3Packages; [ dbus-python pillow pyusb pybluez pyserial pycups ]);

    buildPhase = ''
      LC_ALL=C
      cd cups
      ppdc -z drv/*
    '';
    installPhase = ''
      mkdir -p $out/share/cups/{drv,model/Phomemo}
      mkdir -p $out/lib/cups/{filter,backend}

      cp drv/*.drv $out/share/cups/drv/
      cp ppd/*.ppd.gz $out/share/cups/model/Phomemo

      mkdir -p $out/unwrapped

      install filter/*.py backend/*.py $out/unwrapped


      makeWrapper $out/unwrapped/rastertopm02_t02.py $out/lib/cups/filter/rastertopm02_t02 --set PYTHONPATH "$PYTHONPATH"
      makeWrapper $out/unwrapped/rastertopm110.py $out/lib/cups/filter/rastertopm110 --set PYTHONPATH "$PYTHONPATH"

      makeWrapper $out/unwrapped/phomemo.py $out/lib/cups/backend/phomemo --set PYTHONPATH "$PYTHONPATH"
    '';
  };
in
{
  hardware.printers.ensurePrinters = [
    /*
      use `lpinfo` to get driver strings
      lpinfo -m | grep -i phomemo
      # Phomemo/Phomemo-M02.ppd.gz Phomemo M02
      # drv:///phomemo-m02_t02.drv/Phomemo-M02.ppd Phomemo M02
      # Phomemo/Phomemo-M110.ppd.gz Phomemo M110
      # drv:///phomemo-m110.drv/Phomemo-M110.ppd Phomemo M110
      # Phomemo/Phomemo-T02.ppd.gz Phomemo T02
      # drv:///phomemo-m02_t02.drv/Phomemo-T02.ppd Phomemo T02
    */
    {
      model = "drv:///phomemo-m110.drv/Phomemo-M110.ppd";
      # deviceUri is not the Serial number but the bluetooth MAC address, as reported by `bluetootctl``
      deviceUri = "phomemo://0F1337AF0000";
      location = "Home";
      name = "Phomemo";
    }
  ];

  services.printing = {
    enable = true;
    drivers = [ phomemo-tools ];
  };
}
