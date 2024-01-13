# mpv-config

The following scripts were modified or coded entirely by me:
* ```open_anilist_page.lua```
* ```better_ss.lua```
* ```debug.lua```
* ```mkcast.lua```
* ```open_folder.lua```
* ```open_folder_on_quit.lua```
* ```skipchapters.lua```
* ```speed_control.lua```
* ```ss2clip.lua```
* ```sub_export.lua```
* ```sub_export_clipboard.lua```
* ```subs2clip.lua```
* ```time_remaining.lua```
* ```chapters_to_skip.lua```
* ```ass2txt.lua```

Be careful with ```open_folder.lua``` and ```open_folder_on_quit.lua``` because they use sww/setwindow. ```open_folder(v2).lua``` in ```unused-scripts``` should work without setwindow.

utils directory in scripts should be .utils

Quite a few scripts rely on x11, and I'll have to address that when I move to Wayland.

Some scripts are very specific to my directory peculiarities, although I try to make modifiable config options.
