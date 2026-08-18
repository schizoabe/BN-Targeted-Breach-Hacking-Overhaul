
module FilthyAccessPoints

public class FilthyAccessPointsTutorialSystem extends ScriptableSystem {
    private persistent let m_tutorialDisplayed: Bool;

    public static func GetInstance(gi: GameInstance) -> ref<FilthyAccessPointsTutorialSystem> {
        return GameInstance.GetScriptableSystemsContainer(gi).Get(n"FilthyAccessPoints.FilthyAccessPointsTutorialSystem") as FilthyAccessPointsTutorialSystem;
    }

    public func ShowTutorial(player: ref<GameObject>) -> Void {

    }
}
