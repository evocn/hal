// Mak
// Scene
// Alex Hartford
// September 2023

using program_state : struct {
    current_scene : Scene = .GAME;
    prior_scene : Scene;

    imgui_capturing_mouse    := false;
    imgui_capturing_keyboard := false;

    framerate : float;
}

//
//

Scene :: enum {
    GAME;
    EDITOR;
    MENU;
}

switch_scene :: (new_scene: Scene) {
    prior_scene = current_scene;
    current_scene = new_scene;
}

return_to_prior_scene :: () {
    current_scene, prior_scene = swap(current_scene, prior_scene);
}
