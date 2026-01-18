import 'package:al_farouq_factory/utils/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppStyles {
  static TextStyle bold20Primary = GoogleFonts.inter(
    color: AppColors.primary,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  static TextStyle bold16Primary = GoogleFonts.inter(
    color: AppColors.primary,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  static TextStyle semi16Primary = GoogleFonts.inter(
    color: AppColors.primary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static TextStyle semi16black = GoogleFonts.inter(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: AppColors.black,
  );
  static TextStyle semi16white = GoogleFonts.inter(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: AppColors.white,
  );
  static TextStyle semi20white = GoogleFonts.inter(
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    fontSize: 20,
  );

}
