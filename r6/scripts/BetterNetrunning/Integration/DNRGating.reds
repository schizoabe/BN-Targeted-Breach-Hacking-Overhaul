


















module BetterNetrunning.Integration

import BetterNetrunningConfig.*
import BetterNetrunning.Core.*

@if(ModuleExists("DNR.Replace"))
import DNR.Core.*

@if(ModuleExists("DNR.Replace"))
import DNR.Settings.*



@if(ModuleExists("DNR.Replace"))
public func ApplyDNRDaemonGating(
  programs: script_ref<array<MinigameProgramData>>,
  devPS: ref<SharedGameplayPS>,
  isRemoteBreach: Bool,
  player: wref<PlayerPuppet>,
  entity: wref<Entity>
) -> Void {

  let dnrSubnetsBreached: Bool = IsDefined(devPS)
    && BreachStatusUtils.IsBasicBreached(devPS)
    && BreachStatusUtils.IsNPCsBreached(devPS);

  if !dnrSubnetsBreached {
    DNR_BP_RemoveAllDNRPrograms(programs);
    return;
  }


  let s: ref<DNR_Settings> = DNR_Svc();


  if IsDefined(s) && s.bpdeviceRequiresQueueMastery && !DNR_PlayerHasQueueMastery(player) {
    DNR_BP_RemoveAllDNRPrograms(programs);
    return;
  }


  if IsDefined(s) && s.bpdeviceRequiresNetworkBreached {
    if !DNR_BP_CheckNetworkBreached(entity, isRemoteBreach) {
      DNR_BP_RemoveAllDNRPrograms(programs);
      return;
    }
  }


  DNR_BP_AddQualifiedPrograms(player, programs, isRemoteBreach);


  DNR_BP_RemoveWrongVariant(programs, isRemoteBreach);
}


@if(!ModuleExists("DNR.Replace"))
public func ApplyDNRDaemonGating(
  programs: script_ref<array<MinigameProgramData>>,
  devPS: ref<SharedGameplayPS>,
  isRemoteBreach: Bool,
  player: wref<PlayerPuppet>,
  entity: wref<Entity>
) -> Void {

}

