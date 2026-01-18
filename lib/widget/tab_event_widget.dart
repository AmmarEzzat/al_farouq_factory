
import 'package:al_farouq_factory/utils/app_colors.dart';
import 'package:flutter/material.dart';

class TabEventWidget extends StatelessWidget {
  bool isSelected;
  String eventName;
  Color backgroundColor;
  TextStyle textSelectedStyle;
  TextStyle textUnSelectedStyle;
  Color? borderColor;
  String? icontabSelected;
  String? icontabisNotSelected;

  TabEventWidget({
    super.key,

    required this.isSelected,
    this.icontabSelected,
    this.icontabisNotSelected,
    required this.eventName,
    required this.backgroundColor,
    required this.textSelectedStyle,
    required this.textUnSelectedStyle,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.04,
            vertical: height * 0.006,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(46),

            border: Border.all(
              color: borderColor ?? AppColors.white,
              width: 2,
            ),
            color: isSelected ? backgroundColor : AppColors.transparent,
          ),

          margin: EdgeInsets.all(5),
          child: Row(spacing: width*0.02,
            children: [
              isSelected  ?(icontabSelected==null?SizedBox():

              Image.asset(icontabSelected!,color: AppColors.white,))

                  :
              (icontabisNotSelected==null?SizedBox():

              Image.asset(icontabisNotSelected!,color: AppColors.primary,) ),


              Text(
                eventName,
                style: isSelected ? textSelectedStyle : textUnSelectedStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
