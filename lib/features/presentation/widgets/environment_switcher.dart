import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:getstream_flutter_example/core/di/injector.dart';
import 'package:getstream_flutter_example/features/data/repo/app_preferences.dart';
import 'package:getstream_flutter_example/features/data/services/token_service.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';


class EnvironmentSwitcher extends StatefulWidget {
  const EnvironmentSwitcher({
    super.key,
    required this.currentEnvironment,
  });

  final EnvEnum currentEnvironment;

  @override
  State<EnvironmentSwitcher> createState() => _EnvironmentSwitcherState();
}

class _EnvironmentSwitcherState extends State<EnvironmentSwitcher> {
  late EnvEnum selectedEnvironment;

  @override
  void initState() {
    selectedEnvironment = widget.currentEnvironment;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final streamVideoTheme = StreamVideoTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: CupertinoColors.activeGreen,
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                selectedEnvironment.displayName,
                style: streamVideoTheme.textTheme.footnoteBold
                    .apply(color: CupertinoColors.activeGreen),
              ),
            ),
          ),
          MenuAnchor(
            style: const MenuStyle(
              alignment: Alignment.bottomLeft,
              backgroundColor:
                  WidgetStatePropertyAll(CupertinoColors.black),
            ),
            alignmentOffset: const Offset(-70, 0),
            builder: (
              BuildContext context,
              MenuController controller,
              Widget? child,
            ) {
              return IconButton(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
              );
            },
            menuChildren: [
              ...EnvEnum.values
                  .map(
                    (env) => MenuItemButton(
                      onPressed: () async {
                        await locator<AppPreferences>().setEnvEnum(env);

                        setState(() {
                          selectedEnvironment = env;
                        });
                      },
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedEnvironment == env
                                ? CupertinoColors.activeGreen
                                : Colors.white,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            env.displayName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selectedEnvironment == env
                                  ? CupertinoColors.activeGreen
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList()
            ],
          ),
        ],
      ),
    );
  }
}

class EnvironmentBanner extends StatelessWidget {
  const EnvironmentBanner({
    super.key,
    required this.currentEnvironment,
  });

  final EnvEnum currentEnvironment;

  @override
  Widget build(BuildContext context) {
    final streamVideoTheme = StreamVideoTheme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: CupertinoColors.activeGreen,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          currentEnvironment.displayName,
          style: streamVideoTheme.textTheme.footnoteBold
              .apply(color: CupertinoColors.activeGreen),
        ),
      ),
    );
  }
}
