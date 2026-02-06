import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/common/widgets/video_popup_menu.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';

// 视频卡片 - 垂直布局
class VideoCardV extends StatelessWidget {
  static final shortFormat = DateFormat('M-d');
  static final longFormat = DateFormat('yy-M-d');
  final BaseRecVideoItemModel videoItem;
  final VoidCallback? onRemove;

  const VideoCardV({
    super.key,
    required this.videoItem,
    this.onRemove,
  });

  Future<void> onPushDetail(String heroTag) async {
    String? goto = videoItem.goto;
    switch (goto) {
      case 'bangumi':
        PageUtils.viewPgc(epId: videoItem.param!);
        break;
      case 'av':
        String bvid = videoItem.bvid ?? IdUtils.av2bv(videoItem.aid!);
        int? cid =
            videoItem.cid ??
            await SearchHttp.ab2c(aid: videoItem.aid, bvid: bvid);
        if (cid != null) {
          PageUtils.toVideoPage(
            aid: videoItem.aid,
            bvid: bvid,
            cid: cid,
            cover: videoItem.cover,
            title: videoItem.title,
          );
        }
        break;
      case 'picture':
        try {
          PiliScheme.routePushFromUrl(videoItem.uri!);
        } catch (err) {
          SmartDialog.showToast(err.toString());
        }
        break;
      default:
        if (videoItem.uri?.isNotEmpty == true) {
          PiliScheme.routePushFromUrl(videoItem.uri!);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    void onLongPress() => imageSaveDialog(
      title: videoItem.title,
      cover: videoItem.cover,
      bvid: videoItem.bvid,
    );

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => onPushDetail(Utils.makeHeroTag(videoItem.aid)),
        onLongPress: onLongPress,
        onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 封面图区域 (包含播放数据和时长)
            AspectRatio(
              aspectRatio: StyleString.aspectRatio,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  return Stack(
                    children: [
                      NetworkImgLayer(
                        src: videoItem.cover,
                        width: boxConstraints.maxWidth,
                        height: boxConstraints.maxHeight,
                        type: .emote,
                      ),
                      // 底部渐变背景，辅助文字辨识
                      const Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 25,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black38, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      // 封面左下角：统计
                      Positioned(
                        left: 6,
                        bottom: 4,
                        child: Row(
                          children: [
                            StatWidget(
                              type: StatType.play,
                              value: videoItem.stat.view,
                              color: Colors.white,
                              iconSize: 12,
                            ),
                            const SizedBox(width: 8),
                            if (videoItem.goto != 'picture')
                              StatWidget(
                                type: StatType.danmaku,
                                value: videoItem.stat.danmu,
                                color: Colors.white,
                                iconSize: 12,
                              ),
                          ],
                        ),
                      ),
                      // 封面右下角：时长
                      if (videoItem.duration > 0)
                        Positioned(
                          bottom: 4,
                          right: 6,
                          child: PBadge(
                            size: PBadgeSize.small,
                            type: PBadgeType.gray,
                            isStack: false,
                            text: DurationUtils.formatDuration(
                              videoItem.duration,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            // 2. 文字内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 4, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            videoItem.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.3,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        // 点赞
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            // 使用 InkWell 或 GestureDetector 增加点击反馈
                            InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(
                                4,
                              ), // 点击的水波纹效果范围
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    // 如果你本地能判断是否已点赞，可以切换图标：Icons.thumb_up_alt (实心)
                                    Icons.thumb_up_alt_outlined,
                                    size: 14, // 稍微缩小一点以适应文字
                                  ),
                                  // 判断如果有 likeCount 且大于 0，则显示
                                  if (videoItem.stat.like != null &&
                                      videoItem.stat.like! > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 2),
                                      child: Text(
                                        "${videoItem.stat.like ?? 0}", // 使用你工具类里的格式化方法（如1.2万）
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          height: 1.3,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // 更多按钮
                        if (videoItem.goto == 'av')
                          VideoPopupMenu(
                            iconSize: 18,
                            videoItem: videoItem,
                            onRemove: onRemove,
                          ),
                      ],
                    ),
                    Expanded(
                      child: authorLine(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget authorLine(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = TextStyle(
      fontSize: 11,
      color: theme.colorScheme.outline,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // “已关注”标签，由于是在一行内，给一个右边距
        if (videoItem.isFollowed)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: PBadge(
              text: '已关注',
              isStack: false,
              size: PBadgeSize.small,
              type: PBadgeType.secondary,
              fontSize: 9,
            ),
          ),

        // 作者名：使用 Flexible + ellipsis 保证长名字不会挤掉后面的点赞/更多按钮
        if (videoItem.desc != null) ...[
          Flexible(
            child: Text(
              videoItem.desc ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ] else ...[
          Flexible(
            child: Text(
              videoItem.owner.name ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),

          // 时间部分
          if (videoItem.pubdate != null) ...[
            Text(" · ", style: textStyle),
            Text(
              DateFormatUtils.dateFormat(
                videoItem.pubdate,
                short: shortFormat,
                long: longFormat,
              ),
              style: textStyle,
            ),
          ],
        ],
      ],
    );
  }
}
