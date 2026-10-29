import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/Weather.dart';
import '../providers/LieuProvider.dart';

Widget _buildWeatherParams(
  BuildContext context, {
  required IconData icon,
  required String value,
  required String label,
}) {
  final iconColor = Theme.of(context).primaryColor;
  return Expanded(
    child: Column(
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    ),
  );
}

Widget buildWeatherInfo(
  BuildContext context,
  LieuProvider lieuProvider,
  String villeActuelle,
) {
  if (lieuProvider.isWeatherLoading) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
  final weather = lieuProvider.weather;
  if (weather == null) {
    final errorMessage = lieuProvider.errorMessage ?? 'Metteo non disponible';
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        errorMessage,
        style: const TextStyle(fontSize: 16, color: Colors.red),
      ),
    );
  }
  final weatherIconUrl =
      'https://openweathermap.org/img/wn/${weather.icon}@2x.png';
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  return Card(
    elevation: 8, // Increased elevation
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    margin: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF424242), const Color(0xFF212121)]
              : [Colors.white, const Color(0xFFE0F7FA)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 600),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                Text(
                  'Ville: $villeActuelle',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  // Calcul de l'heure locale : UTC + timezone offset (secondes)
                  '${DateTime.now().toUtc().add(Duration(seconds: weather.timezone)).hour.toString().padLeft(2, '0')}:${DateTime.now().toUtc().add(Duration(seconds: weather.timezone)).minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 5),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        WeatherIconAnimated(url: weatherIconUrl),
                        const SizedBox(width: 10.0),
                        Text(
                          '${weather.temperature.round()}°C',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                    Flexible(
                      child: Text(
                        weather.description.toUpperCase(),
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15.0),
                Center(
                  child: Text(
                    'Min: ${weather.temperatureMin.round()}°C - Max: ${weather.temperatureMax.round()}°C',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWeatherParams(
                      context,
                      icon: Icons.water_drop_outlined,
                      value: '${weather.humidite.round()}%',
                      label: 'Humidité',
                    ),
                    _buildWeatherParams(
                      context,
                      icon: Icons.vertical_align_center,
                      value: '${weather.pression.round()} hPa',
                      label: 'Pression',
                    ),
                    _buildWeatherParams(
                      context,
                      icon: Icons.air,
                      value: '${(weather.vitesseVent * 3.6).round()} km/h',
                      label: 'Vent',
                    ),
                    _buildWeatherParams(
                      context,
                      icon: Icons.cloudy_snowing,
                      value: '${weather.pluie.toStringAsFixed(1)}mm',
                      label: 'Pluie',
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWeatherParams(
                      context,
                      icon: Icons.air,
                      value: '${weather.directionVent.round()}°',
                      label: 'Direction',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class WeatherIconAnimated extends StatefulWidget {
  final String url;
  const WeatherIconAnimated({super.key, required this.url});

  @override
  State<WeatherIconAnimated> createState() => _WeatherIconAnimatedState();
}

class _WeatherIconAnimatedState extends State<WeatherIconAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Image.network(widget.url, width: 60, height: 60),
    );
  }
}
