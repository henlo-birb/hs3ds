#!/usr/bin/python3.10
from PIL import Image
import os
import argparse
import luadata
import math
import time
from multiprocessing import Pool

parser = argparse.ArgumentParser(
    description="convert gif to simple texture atlas")
parser.add_argument("-j",
                    action="store_true",
                    help="just generate data, not atlases")
parser.add_argument("-s", type=int, help="percentage scale factor")
parser.add_argument("-f", action="store_true", help="force regenerate all images even if they already exist")

args = parser.parse_args()

gifs = [a for a in os.listdir(".") if a.endswith(".gif")]


os.system("mkdir -p animations")

def f(g):
    cols = 3
    rows = 4
    scale = args.s or 50
    anim_name = g.replace(".gif", "")
    with Image.open(g) as im:
        w = int(im.width * scale / 100)
        h = int(im.height * scale / 100)
        counter = 0
        atlases = []
        data = {
            "n_frames": im.n_frames,
            "width": w,
            "height": h,
            "cols": cols,
            "rows": rows,
            "durations": [],
            "atlas_width": w * cols,
            "atlas_height": h * rows,
            "animated": im.n_frames > 1
        }
        for i in range(im.n_frames):
            if counter == 0:
                atlases.append(Image.new(
                    "RGB", (w * cols, h * rows)))  # create new atlas if needed

            im.seek(i)  # go to next frame

            data["durations"].append(
                im.info["duration"])  # update duration info

            frame = Image.new(
                "RGB",
                (im.width, im.height))  # create image to use for scaling
            frame.paste(im)  # paste current frame to scalable copy
            frame.thumbnail((w, h), Image.ANTIALIAS)  # scale the frame

            atlases[-1].paste(frame, (counter % cols * w, counter // cols *
                                      h))  # paste into current atlas
            counter += 1  # increment counter
            counter %= cols * rows  # reset counter if needed
        data["n_atlases"] = len(atlases)
        luadata.write(f"animations/{anim_name}.lua", data, indent="\t")
        pil_output = anim_name + ".png"
        if not args.j:
            for i, atl in enumerate(atlases):
                output_tex = g.replace('.gif', f'_{i + 1}.t3x')
                if args.f or not output_tex in os.listdir("animations"):
                    atl.save(pil_output)  # save atlas to png
                    cmd = f"tex3ds {pil_output} -o animations/{output_tex} > /dev/null"  # generate t3x file, 1 indexed because lua is stupid
                    os.system(cmd)
                    os.system(f"rm {pil_output}")

start = time.time()

with Pool(5) as p:
    p.map(f, gifs)

print(f"time elapsed: {time.time() - start}")