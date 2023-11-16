{
  outputs = {self, ...}: { 
    flakeModules.default = ./flakeModules/default.nix; 
    flakeModule = self.flakeModules.default;
  };
}
