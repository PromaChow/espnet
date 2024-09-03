import configargparse
import shutil
from pathlib import Path


if __name__ == "__main__":
    # parser
    parser = configargparse.ArgumentParser(
        description="Copy TEMPLATE folder's markdown to dst folder",
        config_file_parser_class=configargparse.YAMLConfigFileParser,
        formatter_class=configargparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--src", type=Path, help="Path to TEMPLATE folder")
    parser.add_argument(
        "--dst", type=Path, help="Destination to store markdowns")
    args = parser.parse_args()
    print(args)

    args.dst.mkdir(parents=True, exist_ok=True)
    for recipe in args.src.glob("*/*.md"):
        shutil.copyfile(recipe, args.dst / f"{recipe.parent.name}.md")
    shutil.copyfile(args.src / "README.md", args.dst / "README.md")
